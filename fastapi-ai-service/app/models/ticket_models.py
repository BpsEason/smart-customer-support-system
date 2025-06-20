from pydantic import BaseModel
from typing import Optional

# 這個模型可能用於 FastAPI 內部接收工單分配的請求，或只是作為 ChatbotResponse 的一部分
class DispatchRequest(BaseModel):
    ticket_id: int
    message: str
    sentiment: str # 由情感分析服務提供

class DispatchResponse(BaseModel):
    assigned_to_user_id: Optional[int]
    needs_human_attention: bool
    dispatch_reason: str