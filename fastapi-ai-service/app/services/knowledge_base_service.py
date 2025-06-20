# knowledge_base_service.py
import os
import json
from typing import List, Dict, Any

class KnowledgeBaseService:
    def __init__(self):
        self.kb_path = os.path.join(os.getenv('DATA_DIR', '/app/data'), 'knowledge_base.json')
        self.knowledge_base = self._load_knowledge_base()

    def _load_knowledge_base(self) -> List[Dict[str, str]]:
        if os.path.exists(self.kb_path):
            with open(self.kb_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        else:
            print(f"Warning: Knowledge base file not found at {self.kb_path}. Using dummy data.")
            return [
                {"id": 1, "title": "如何重設密碼", "content": "您可以通過訪問我們的網站登錄頁面，點擊 '忘記密碼' 鏈接，然後按照指示輸入您的註冊郵箱來重設密碼。", "keywords": ["密碼", "重設", "忘記"]},
                {"id": 2, "title": "查詢訂單狀態", "content": "登錄您的帳戶後，進入 '我的訂單' 頁面，您可以查看所有訂單的即時狀態和物流信息。", "keywords": ["訂單", "狀態", "物流", "查詢"]},
                {"id": 3, "title": "退換貨政策", "content": "我們的退換貨政策允許在收到商品後7天內申請退貨，15天內申請換貨。具體條款請參考官網 '退換貨說明'。", "keywords": ["退貨", "換貨", "政策"]},
                {"id": 4, "title": "聯繫客服", "content": "如果您需要人工協助，可以通過在線聊天、發送郵件到 support@example.com 或撥打客服熱線 0800-123-456 聯繫我們。", "keywords": ["客服", "聯繫", "電話", "郵件", "人工"]}
            ]

    def search_knowledge_base(self, intent: str, query: str = "") -> List[Dict[str, str]]:
        results = []
        # 根據意圖和關鍵字進行模擬搜索
        for item in self.knowledge_base:
            if intent in ["password_reset"] and any(k in item['keywords'] for k in ["密碼", "重設"]):
                results.append({"id": item['id'], "title": item['title'], "summary": item['content'][:100] + "..."})
            elif intent in ["delivery_status"] and any(k in item['keywords'] for k in ["訂單", "物流"]):
                results.append({"id": item['id'], "title": item['title'], "summary": item['content'][:100] + "..."})
            elif intent in ["human_transfer"] and any(k in item['keywords'] for k in ["客服", "聯繫"]):
                results.append({"id": item['id'], "title": item['title'], "summary": item['content'][:100] + "..."})
            elif query and any(keyword in query for keyword in item['keywords']):
                results.append({"id": item['id'], "title": item['title'], "summary": item['content'][:100] + "..."})
        return results[:2] # 返回最多兩個建議
