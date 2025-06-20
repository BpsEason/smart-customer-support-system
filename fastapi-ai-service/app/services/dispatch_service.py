# dispatch_service.py
from typing import Optional

class DispatchService:
    def __init__(self):
        # 模擬可用的客服代理或部門
        self.agents = ["Agent_A", "Agent_B", "Technical_Support", "Sales_Team"]

    def dispatch_ticket(self, message: str, sentiment: str, intent: str) -> Optional[str]:
        # 根據情感和意圖進行模擬分派
        if sentiment == "negative" and intent in ["password_reset", "delivery_status"]:
            return "Agent_A" # 負面情緒且是常見問題，優先處理
        elif intent == "human_transfer":
            return "Agent_B" # 直接要求人工
        elif intent == "technical_issue": # 假設有這個意圖
            return "Technical_Support"
        elif intent == "product_inquiry":
            return "Sales_Team"
        elif sentiment == "positive" or sentiment == "neutral":
            return "Agent_B" # 普通問題可以分配給通用客服
        
        return "Agent_A" # 默認分配
