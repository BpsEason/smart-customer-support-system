from fastapi import APIRouter
from pydantic import BaseModel
import logging
from app.services.sentiment_service import sentiment_service # 導入服務實例
from app.services.exceptions import InvalidInputError, APIException

router = APIRouter()
logger = logging.getLogger(__name__)

class SentimentRequest(BaseModel):
    text: str

class SentimentResponse(BaseModel):
    sentiment: str # 'positive', 'negative', 'neutral'
    score: float

@router.post("/", response_model=SentimentResponse)
async def get_sentiment(request: SentimentRequest):
    """
    分析輸入文本的情感傾向 (正面、負面、中立)。
    """
    if not request.text or not request.text.strip():
        raise InvalidInputError(detail="Input text cannot be empty or just whitespace.")

    try:
        sentiment, score = sentiment_service.analyze_sentiment(request.text)
        return SentimentResponse(sentiment=sentiment, score=score)
    except APIException as e:
        raise e
    except Exception as e:
        logger.exception("Unexpected error in sentiment analysis API.")
        raise APIException(status_code=500, message="Failed to perform sentiment analysis.", code="SENTIMENT_ERROR")
