from pydantic import BaseModel
from typing import Optional

class ChatbotRequest(BaseModel):
    message: str

class ChatbotResponse(BaseModel):
    intent: str
    reply: str
    confidence: float
