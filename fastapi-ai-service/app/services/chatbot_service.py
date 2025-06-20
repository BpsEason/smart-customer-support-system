# chatbot_service.py
import os
import json
import joblib
from typing import Tuple, Dict, Any
import random

class ChatbotService:
    def __init__(self):
        self.model_path = os.path.join(os.getenv('MODEL_DIR', '/app/models'), 'chatbot_pipeline.pkl')
        self.intent_data_path = os.path.join(os.getenv('DATA_DIR', '/app/data'), 'intents.json')
        self.pipeline = self._load_model()
        self.intents = self._load_intent_data()
        self._train_dummy_model() # 訓練一個簡單的模擬模型

    def _load_model(self):
        # 實際應載入訓練好的模型
        if os.path.exists(self.model_path):
            try:
                return joblib.load(self.model_path)
            except Exception as e:
                print(f"Error loading model from {self.model_path}: {e}. Using dummy model.")
                return self._create_dummy_model()
        else:
            print(f"Warning: Chatbot model not found at {self.model_path}. Using dummy model.")
            return self._create_dummy_model()

    def _create_dummy_model(self):
        from sklearn.feature_extraction.text import TfidfVectorizer
        from sklearn.svm import LinearSVC
        from sklearn.pipeline import Pipeline
        # 簡單的模擬模型骨架
        return Pipeline([
            ('tfidf', TfidfVectorizer()),
            ('clf', LinearSVC())
        ])

    def _train_dummy_model(self):
        # 用 intents.json 中的數據簡單訓練一下，讓 predict_intent 稍微有點依據
        phrases = []
        labels = []
        for intent in self.intents['intents']:
            for pattern in intent['patterns']:
                phrases.append(pattern)
                labels.append(intent['tag'])
        if phrases and labels:
            try:
                self.pipeline.fit(phrases, labels)
                print("Dummy chatbot model trained.")
            except Exception as e:
                print(f"Could not train dummy model: {e}")

    def _load_intent_data(self):
        # 簡單的意圖與回覆映射，用於模擬
        if os.path.exists(self.intent_data_path):
            with open(self.intent_data_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        else:
            print(f"Warning: Intent data not found at {self.intent_data_path}. Using dummy data.")
            return {
                "intents": [
                    {"tag": "greeting", "patterns": ["你好", "嗨", "哈囉", "您好"], "responses": ["您好！有什麼可以幫您的嗎？", "嗨！很高興為您服務。"]},
                    {"tag": "password_reset", "patterns": ["忘記密碼", "重設密碼", "密碼問題"], "responses": ["請您前往官網的「忘記密碼」頁面，按照步驟進行操作即可。", "重設密碼流程：請點擊連結 [重設密碼連結]。"]},
                    {"tag": "delivery_status", "patterns": ["包裹在哪", "運送進度", "查詢物流"], "responses": ["請提供您的訂單號碼或追蹤號碼，我將為您查詢。", "目前系統顯示您的包裹正在運送途中，預計很快到達。"]},
                    {"tag": "product_inquiry", "patterns": ["產品資訊", "這個產品好嗎", "了解產品"], "responses": ["您想了解哪個產品的資訊呢？", "請告訴我產品名稱，我可以為您查詢相關資料。"]},
                    {"tag": "goodbye", "patterns": ["再見", "掰掰", "謝謝"], "responses": ["再見！很高興為您服務。", "期待下次再見！感謝您的提問。"]},
                    {"tag": "human_transfer", "patterns": ["轉接人工", "找人", "客服", "人工服務"], "responses": ["好的，我將為您轉接人工客服。請稍候，我們會盡快為您服務。"]},
                    {"tag": "fallback", "patterns": [], "responses": ["抱歉，我還在學習中，暫時無法理解您的問題。您可以嘗試換個說法，或者我為您轉接人工客服。", "這似乎超出了我的能力範圍，是否需要轉接人工客服為您處理？", "很抱歉，我無法處理您的請求。請您清晰描述問題，或等待人工客服支援。"]}
                ]
            }

    def predict_intent(self, text: str) -> Tuple[str, float]:
        if not self.pipeline: # 如果模型沒有成功加載或訓練
            # 簡單的關鍵字匹配作為回退
            text_lower = text.lower()
            if any(word in text_lower for word in ["你好", "嗨"]):
                return "greeting", 0.9
            elif any(word in text_lower for word in ["密碼", "忘記", "重設"]):
                return "password_reset", 0.8
            elif any(word in text_lower for word in ["包裹", "運送", "物流"]):
                return "delivery_status", 0.8
            elif any(word in text_lower for word in ["產品", "資訊"]):
                return "product_inquiry", 0.7
            elif any(word in text_lower for word in ["轉接", "人工", "客服"]):
                return "human_transfer", 0.9
            elif any(word in text_lower for word in ["再見", "謝謝", "掰掰"]):
                return "goodbye", 0.9
            return "fallback", 0.5

        try:
            # 實際使用模型預測
            predicted_tag = self.pipeline.predict([text])[0]
            # 假設我們沒有 predict_proba，給一個固定的高置信度
            return predicted_tag, 0.85
        except Exception as e:
            print(f"Error during intent prediction: {e}. Falling back to keyword matching.")
            return "fallback", 0.5 # 發生錯誤時回退

    def get_reply(self, intent_tag: str, original_message: str = "") -> str:
        # 根據意圖標籤查找對應的回覆
        for intent in self.intents['intents']:
            if intent['tag'] == intent_tag:
                reply = random.choice(intent['responses'])
                # 可以根據原始訊息進一步個性化回覆，例如提取關鍵信息
                if intent_tag == "password_reset" and "用戶名" in original_message:
                    reply += "請提供您的用戶名，我將引導您重設密碼。"
                return reply
        return "抱歉，我沒有找到相關的回覆." # Fallback for reply
