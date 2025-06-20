from pydantic import BaseModel
from typing import Optional

class SentimentRequest(BaseModel):
    text: str

class SentimentResponse(BaseModel):
    sentiment: str # e.g., 'positive', 'negative', 'neutral'
    confidence: float # confidence score for the sentiment
