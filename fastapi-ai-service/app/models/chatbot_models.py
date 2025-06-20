from pydantic import BaseModel
from typing import Optional

class ChatbotRequest(BaseModel):
    ticket_id: int
    message: str
    customer_id: str # 例如客戶的 email
    # 可選的額外信息，例如來源渠道
    source: Optional[str] = None

class ChatbotResponse(BaseModel):
    intent: str
    reply: str
    confidence: float
    needs_human_attention: bool = False
    assigned_to_user_id: Optional[int] = None
    faq_recommendations: Optional[list] = None