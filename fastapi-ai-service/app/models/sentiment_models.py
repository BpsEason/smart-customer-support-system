from pydantic import BaseModel
from typing import Optional

class SentimentRequest(BaseModel):
    text: str

class SentimentResponse(BaseModel):
    sentiment: str # 例如 positive, negative, neutral, urgent
    confidence: float