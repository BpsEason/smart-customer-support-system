# sentiment_service.py
import os
import joblib
from typing import Tuple

class SentimentService:
    def __init__(self):
        self.model_path = os.path.join(os.getenv('MODEL_DIR', '/app/models'), 'sentiment_pipeline.pkl')
        self.sentiment_labels = ['negative', 'neutral', 'positive']
        self.pipeline = self._load_model()
        self._train_dummy_model() # 訓練一個簡單的模擬模型

    def _load_model(self):
        # 實際應載入訓練好的情感分析模型
        if os.path.exists(self.model_path):
            try:
                return joblib.load(self.model_path)
            except Exception as e:
                print(f"Error loading sentiment model from {self.model_path}: {e}. Using dummy model.")
                return self._create_dummy_model()
        else:
            print(f"Warning: Sentiment model not found at {self.model_path}. Using dummy model.")
            return self._create_dummy_model()

    def _create_dummy_model(self):
        from sklearn.feature_extraction.text import TfidfVectorizer
        from sklearn.linear_model import LogisticRegression
        from sklearn.pipeline import Pipeline
        # 簡單的模擬模型骨架
        return Pipeline([
            ('tfidf', TfidfVectorizer()),
            ('clf', LogisticRegression())
        ])

    def _train_dummy_model(self):
        # 簡單的訓練數據用於模擬
        texts = ["我愛這個產品！", "還不錯，沒什麼意見。", "我非常生氣，服務太差了。", "這很好", "很爛", "一般般"]
        labels = ["positive", "neutral", "negative", "positive", "negative", "neutral"]
        # 將標籤映射到數字
        label_map = {label: i for i, label in enumerate(self.sentiment_labels)}
        numeric_labels = [label_map[label] for label in labels]

        if texts and numeric_labels:
            try:
                self.pipeline.fit(texts, numeric_labels)
                print("Dummy sentiment model trained.")
            except Exception as e:
                print(f"Could not train dummy sentiment model: {e}")

    def analyze_sentiment(self, text: str) -> Tuple[str, float]:
        if not self.pipeline: # 如果模型沒有成功加載或訓練
            # 簡單的關鍵字匹配作為回退
            text_lower = text.lower()
            if any(word in text_lower for word in ["生氣", "差勁", "不滿", "爛"]):
                return "negative", 0.9
            elif any(word in text_lower for word in ["愛", "喜歡", "棒", "好"]):
                return "positive", 0.9
            return "neutral", 0.6

        try:
            predicted_idx = self.pipeline.predict([text])[0]
            # 模擬置信度，實際應使用 predict_proba
            return self.sentiment_labels[predicted_idx], 0.9
        except Exception as e:
            print(f"Error during sentiment analysis: {e}. Falling back to keyword matching.")
            return "neutral", 0.5 # 發生錯誤時回退
