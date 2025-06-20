import logging
from typing import Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.pipeline import Pipeline
import joblib
import os
from app.services.exceptions import ModelLoadingError, PredictionError

logger = logging.getLogger(__name__)

# 模擬情感訓練數據 (簡化)
# 實際中會需要更大、更平衡的數據集
SENTIMENT_TRAINING_DATA = [
    ("我非常滿意你們的服務，感謝！", "positive"),
    ("問題解決得很快，很棒！", "positive"),
    ("沒有任何問題，一切都很好", "positive"),
    ("你們的服務真是太棒了，我會推薦給朋友！", "positive"),
    ("糟糕透了，我非常不滿意", "negative"),
    ("這是一個很差的體驗，無法接受", "negative"),
    ("客服回應太慢了，我很生氣", "negative"),
    ("我的問題沒有得到解決，我很失望", "negative"),
    ("我不確定這個功能怎麼用", "neutral"),
    ("我只是想問一個問題", "neutral"),
    ("收到你們的訊息了", "neutral"),
    ("這項功能似乎需要改進", "neutral"),
]

class SentimentService:
    _instance = None
    _is_initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(SentimentService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._is_initialized:
            self.model_dir = os.getenv("MODEL_DIR", "/app/models")
            self.model_path = os.path.join(self.model_dir, "sentiment_pipeline.pkl")
            self.sentiment_labels = sorted(list(set([label for _, label in SENTIMENT_TRAINING_DATA])))
            self.pipeline = None
            self._load_or_train_model()
            self._is_initialized = True

    def _load_or_train_model(self):
        os.makedirs(self.model_dir, exist_ok=True)
        if os.path.exists(self.model_path):
            try:
                self.pipeline = joblib.load(self.model_path)
                if not hasattr(self.pipeline, 'predict'):
                    raise ValueError("Loaded sentiment pipeline is not valid.")
                logger.info("Sentiment model loaded from disk.")
            except Exception as e:
                logger.warning(f"Failed to load sentiment model (may be corrupted or outdated): {e}. Training new one.")
                self._train_and_save_model()
        else:
            logger.info("Sentiment model not found on disk. Training new one.")
            self._train_and_save_model()

    def _train_and_save_model(self):
        try:
            texts = [data[0] for data in SENTIMENT_TRAINING_DATA]
            labels = [self.sentiment_labels.index(data[1]) for data in SENTIMENT_TRAINING_DATA] # 將標籤轉換為數字索引

            self.pipeline = Pipeline([
                ('tfidf', TfidfVectorizer()),
                ('clf', LinearSVC(random_state=42)) # 加入 random_state
            ])
            self.pipeline.fit(texts, labels)

            joblib.dump(self.pipeline, self.model_path)
            logger.info("Sentiment model trained and saved successfully.")
        except Exception as e:
            raise ModelLoadingError(model_name="Sentiment", detail=f"Training failed: {e}")

    def analyze_sentiment(self, text: str) -> Tuple[str, float]:
        if not self.pipeline:
            raise ModelLoadingError(model_name="Sentiment", detail="Model not initialized.")
        if not text.strip():
            raise PredictionError(model_name="Sentiment", detail="Input text for analysis cannot be empty.")

        try:
            # LinearSVC 不直接提供 predict_proba，這裡模擬一個 confidence score
            # 對於需要概率的場景，可以考慮使用 LogisticRegression 或其他支持概率輸出的分類器
            predicted_label_idx = self.pipeline.predict([text])[0]
            sentiment_label = self.sentiment_labels[predicted_label_idx]
            
            # 簡單模擬置信度，實際應用中需要模型本身的支持
            # 對於基於 SVM 的模型，可以考慮使用 decision_function 的絕對值來作為置信度參考
            # 或者轉換為概率 (雖然不直接，但有些庫提供方法)
            # 這裡我們給一個基於標籤的預設高置信度
            confidence = 0.9 if sentiment_label in ["positive", "negative"] else 0.7 

            logger.debug(f"Analyzed sentiment for '{text}': {sentiment_label} (Score: {confidence:.2f})")
            return sentiment_label, float(confidence)
        except Exception as e:
            raise PredictionError(model_name="Sentiment", detail=f"Prediction failed: {e}")

# 實例化服務 (單例模式)
sentiment_service = SentimentService()
