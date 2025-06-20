from fastapi import APIRouter
from pydantic import BaseModel
import logging
from app.services.dispatch_service import dispatch_service # 導入服務實例
from app.services.exceptions import InvalidInputError, APIException

router = APIRouter()
logger = logging.getLogger(__name__)

class DispatchRequest(BaseModel):
    message: str
    intent: str # 可選，作為輔助判斷
    sentiment: str # 可選，作為輔助判斷

class DispatchResponse(BaseModel):
    recommended_agent_id: int
    category: str
    reason: str
    prediction_confidence: float

@router.post("/", response_model=DispatchResponse)
async def dispatch_customer_ticket(request: DispatchRequest):
    """
    根據工單內容智能判斷問題類別，並推薦最適合的客服人員或部門。
    """
    if not request.message or not request.message.strip():
        raise InvalidInputError(detail="Input message cannot be empty or just whitespace.")

    try:
        predicted_category, confidence = dispatch_service.predict_category(request.message)
        recommended_agent_id, assigned_category, reason = dispatch_service.get_recommended_agent(
            predicted_category, request.sentiment
        )
        return DispatchResponse(
            recommended_agent_id=recommended_agent_id,
            category=assigned_category,
            reason=reason,
            prediction_confidence=confidence
        )
    except APIException as e:
        raise e
    except Exception as e:
        logger.exception("Unexpected error in intelligent dispatch API.")
        raise APIException(status_code=500, message="Failed to perform intelligent dispatch.", code="DISPATCH_ERROR")
