import logging
from typing import Dict, Any, Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
import joblib
import os
from app.services.exceptions import ModelLoadingError, PredictionError

logger = logging.getLogger(__name__)

# 模擬客服人員/部門列表 (這些 ID 應該對應到 Laravel 資料庫中的客服人員 ID)
AGENTS = {
    1: {"name": "技術支援部", "categories": ["technical", "login", "software", "account_lock"], "is_senior": False},
    2: {"name": "帳務部門", "categories": ["billing", "payment", "invoice", "refund"], "is_senior": False},
    3: {"name": "售後服務部", "categories": ["warranty", "return", "delivery", "product_defect"], "is_senior": False},
    4: {"name": "綜合客服部", "categories": ["general", "other", "inquiry"], "is_senior": True}, # 假設綜合客服部有資深客服
    5: {"name": "資深技術支援", "categories": ["technical"], "is_senior": True} # 額外定義一個資深技術客服
}

# 模擬工單分類訓練數據
DISPATCH_TRAINING_DATA = [
    ("我的帳號無法登入", "technical"),
    ("軟體出現bug了", "technical"),
    ("忘記密碼", "technical"),
    ("帳戶被鎖定怎麼辦", "account_lock"), # 新增帳戶鎖定類別
    ("訂單支付失敗", "billing"),
    ("關於我的帳單問題", "billing"),
    ("我想申請退款", "billing"), # 退款可能和帳務也可能和售後有關，需要判斷上下文
    ("商品有瑕疵，要怎麼退貨？", "product_defect"),
    ("我想詢問產品保修政策", "product_defect"),
    ("我的包裹物流異常", "delivery"),
    ("我只是想問個問題", "general"),
    ("感謝你們的服務", "general"),
    ("我想知道你們的營業時間", "general"),
    ("請問有最新的優惠活動嗎", "general"),
]

class DispatchService:
    _instance = None
    _is_initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DispatchService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._is_initialized:
            self.model_dir = os.getenv("MODEL_DIR", "/app/models")
            self.vectorizer_path = os.path.join(self.model_dir, "dispatch_vectorizer.pkl")
            self.model_path = os.path.join(self.model_dir, "dispatch_model.pkl")
            self.categories = sorted(list(set([label for _, label in DISPATCH_TRAINING_DATA])))
            self.vectorizer = None
            self.model = None
            self._load_or_train_model()
            self._is_initialized = True

    def _load_or_train_model(self):
        os.makedirs(self.model_dir, exist_ok=True)
        if os.path.exists(self.vectorizer_path) and os.path.exists(self.model_path):
            try:
                self.vectorizer = joblib.load(self.vectorizer_path)
                self.model = joblib.load(self.model_path)
                if not hasattr(self.vectorizer, 'transform') or not hasattr(self.model, 'predict'):
                    raise ValueError("Loaded model or vectorizer is not valid.")
                logger.info("Dispatch model loaded from disk.")
            except Exception as e:
                logger.warning(f"Failed to load dispatch model (may be corrupted or outdated): {e}. Training new one.")
                self._train_and_save_model()
        else:
            logger.info("Dispatch model not found on disk. Training new one.")
            self._train_and_save_model()

    def _train_and_save_model(self):
        try:
            texts = [data[0] for data in DISPATCH_TRAINING_DATA]
            labels = [data[1] for data in DISPATCH_TRAINING_DATA]

            self.vectorizer = TfidfVectorizer()
            X = self.vectorizer.fit_transform(texts)
            y = [self.categories.index(label) for label in labels]

            self.model = MultinomialNB() # 簡單的分類器
            self.model.fit(X, y)

            joblib.dump(self.vectorizer, self.vectorizer_path)
            joblib.dump(self.model, self.model_path)
            logger.info("Dispatch model trained and saved successfully.")
        except Exception as e:
            raise ModelLoadingError(model_name="Dispatch", detail=f"Training failed: {e}")

    def predict_category(self, message: str) -> Tuple[str, float]:
        if not self.model or not self.vectorizer:
            raise ModelLoadingError(model_name="Dispatch", detail="Model not initialized.")
        if not message.strip():
            raise PredictionError(model_name="Dispatch", detail="Input message for prediction cannot be empty.")
        try:
            message_vectorized = self.vectorizer.transform([message])
            probabilities = self.model.predict_proba(message_vectorized)[0]
            predicted_category_idx = self.model.predict(message_vectorized)[0]
            
            category = self.categories[predicted_category_idx]
            confidence = probabilities[predicted_category_idx]
            
            logger.debug(f"Predicted category for '{message[:50]}': {category} (Confidence: {confidence:.2f})")
            return category, float(confidence)
        except Exception as e:
            raise PredictionError(model_name="Dispatch", detail=f"Prediction failed: {e}")

    def get_recommended_agent(self, category: str, sentiment: str) -> Tuple[int, str, str]:
        """
        根據預測類別和情感推薦客服人員。
        返回 (agent_id, category_name, reason)
        """
        # 預設為綜合客服部，通常綜合客服部處理範圍廣且可能包含資深客服
        default_agent_id = 4 
        recommended_agent_id = default_agent_id 
        assigned_category = category # 默認分配給預測的類別
        reason = f"Based on message content classification ({category})."

        # 優先尋找與類別匹配的客服
        for agent_id, agent_info in AGENTS.items():
            if category in agent_info["categories"]:
                recommended_agent_id = agent_id
                break
        
        # 如果是負面情緒，嘗試轉接給資深客服 (如果存在資深客服且與類別相關)
        if sentiment == "negative":
            reason += " (Elevated priority due to negative sentiment.)"
            # 優先考慮該類別的資深客服，如果沒有，轉給綜合客服部的資深客服
            found_senior_agent = False
            for agent_id, agent_info in AGENTS.items():
                if agent_info["is_senior"] and category in agent_info["categories"]:
                    recommended_agent_id = agent_id
                    found_senior_agent = True
                    break
            
            if not found_senior_agent and AGENTS[default_agent_id]["is_senior"]:
                recommended_agent_id = default_agent_id # 轉給綜合客服部的資深客服

        return recommended_agent_id, assigned_category.capitalize(), reason

# 實例化服務 (單例模式)
dispatch_service = DispatchService()
