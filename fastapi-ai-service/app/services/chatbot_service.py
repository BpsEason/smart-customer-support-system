import logging
from typing import Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
import joblib
import os
from app.services.exceptions import ModelLoadingError, PredictionError

logger = logging.getLogger(__name__)

# 模擬訓練數據
TRAINING_DATA = [
    ("我想重置我的密碼", "password_reset"),
    ("忘記登入帳號了怎麼辦", "password_reset"),
    ("訂單什麼時候會送到？", "order_status"),
    ("查一下我的訂單號碼", "order_status"),
    ("可以幫我轉接到人工客服嗎？", "transfer_to_agent"),
    ("你們有客服電話嗎？", "transfer_to_agent"),
    ("謝謝你的幫助", "greeting_thanks"),
    ("這個產品怎麼使用？", "general_inquiry"),
    ("我需要退款", "refund_request"),
    ("請問可以退貨嗎", "refund_request"),
    ("我的帳單有問題", "billing_issue"),
    ("付款失敗", "billing_issue"),
    ("我想了解產品功能", "product_info"),
    ("如何啟用新功能", "product_info"),
    ("帳戶被鎖定了", "account_lock"),
    ("無法登入", "account_lock"),
]

class ChatbotService:
    _instance = None
    _is_initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ChatbotService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._is_initialized:
            self.model_dir = os.getenv("MODEL_DIR", "/app/models") # 使用環境變數或預設值
            self.vectorizer_path = os.path.join(self.model_dir, "chatbot_vectorizer.pkl")
            self.model_path = os.path.join(self.model_dir, "chatbot_model.pkl")
            self.intents = sorted(list(set([label for _, label in TRAINING_DATA]))) # 確保意圖列表順序一致
            self.vectorizer = None
            self.model = None
            self._load_or_train_model()
            self._is_initialized = True

    def _load_or_train_model(self):
        os.makedirs(self.model_dir, exist_ok=True) # 確保模型目錄存在
        if os.path.exists(self.vectorizer_path) and os.path.exists(self.model_path):
            try:
                self.vectorizer = joblib.load(self.vectorizer_path)
                self.model = joblib.load(self.model_path)
                # 簡單驗證加載的模型是否有效
                if not hasattr(self.vectorizer, 'transform') or not hasattr(self.model, 'predict'):
                     raise ValueError("Loaded model or vectorizer is not valid.")
                logger.info("Chatbot model loaded from disk.")
            except Exception as e:
                logger.warning(f"Failed to load chatbot model (may be corrupted or outdated): {e}. Training new one.")
                self._train_and_save_model()
        else:
            logger.info("Chatbot model not found on disk. Training new one.")
            self._train_and_save_model()

    def _train_and_save_model(self):
        try:
            texts = [data[0] for data in TRAINING_DATA]
            labels = [data[1] for data in TRAINING_DATA]

            self.vectorizer = TfidfVectorizer()
            X = self.vectorizer.fit_transform(texts)
            # 確保標籤到數字索引的映射在訓練和預測時一致
            y = [self.intents.index(label) for label in labels] 

            self.model = LogisticRegression(max_iter=1000, random_state=42) # 加入 random_state 以確保可重複性
            self.model.fit(X, y)

            joblib.dump(self.vectorizer, self.vectorizer_path)
            joblib.dump(self.model, self.model_path)
            logger.info("Chatbot model trained and saved successfully.")
        except Exception as e:
            raise ModelLoadingError(model_name="Chatbot", detail=f"Training failed: {e}")

    def predict_intent(self, text: str) -> Tuple[str, float]:
        if not self.model or not self.vectorizer:
            raise ModelLoadingError(model_name="Chatbot", detail="Model not initialized.")
        if not text.strip():
            raise PredictionError(model_name="Chatbot", detail="Input text for prediction cannot be empty.")
            
        try:
            text_vectorized = self.vectorizer.transform([text])
            probabilities = self.model.predict_proba(text_vectorized)[0]
            predicted_intent_idx = self.model.predict(text_vectorized)[0]
            
            intent = self.intents[predicted_intent_idx]
            confidence = probabilities[predicted_intent_idx]
            
            logger.debug(f"Predicted intent for '{text}': {intent} (Confidence: {confidence:.2f})")
            return intent, float(confidence)
        except Exception as e:
            raise PredictionError(model_name="Chatbot", detail=f"Prediction failed: {e}")

    def get_reply(self, intent: str) -> str:
        replies = {
            "password_reset": "關於密碼重置，您可以訪問我們的幫助中心查看指南，或者我為您轉接人工客服。",
            "order_status": "請問您的訂單號碼是多少？請提供後續查詢。",
            "transfer_to_agent": "好的，我將為您轉接人工客服，請稍候。",
            "greeting_thanks": "不客氣，很高興能為您服務！",
            "refund_request": "請提供您的訂單號和退款原因，我們將為您處理退款事宜。",
            "billing_issue": "請問您遇到了什麼樣的帳單問題？可以詳細說明一下嗎？",
            "product_info": "您對哪款產品感興趣？我可以提供更多資訊。",
            "account_lock": "您的帳戶被鎖定了嗎？請說明詳細情況，我可以嘗試幫助您解鎖或轉接。",
            "general_inquiry": "很抱歉，我目前無法理解您的問題。您能詳細描述一下嗎？或者我可以幫您轉接人工客服。",
        }
        return replies.get(intent, replies["general_inquiry"])

# 實例化服務 (單例模式)
chatbot_service = ChatbotService()
