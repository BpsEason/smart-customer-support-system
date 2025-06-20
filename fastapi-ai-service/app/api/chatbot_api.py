from fastapi import APIRouter
from pydantic import BaseModel
import logging
from app.services.chatbot_service import chatbot_service # 導入服務實例
from app.services.exceptions import InvalidInputError, APIException

router = APIRouter()
logger = logging.getLogger(__name__)

class ChatbotRequest(BaseModel):
    text: str

class ChatbotResponse(BaseModel):
    intent: str
    reply: str
    confidence: float

@router.post("/", response_model=ChatbotResponse)
async def get_chatbot_response(request: ChatbotRequest):
    """
    根據用戶輸入的文本，預測意圖並生成回覆。
    """
    if not request.text or not request.text.strip():
        raise InvalidInputError(detail="Input text cannot be empty or just whitespace.")

    try:
        intent, confidence = chatbot_service.predict_intent(request.text)
        reply = chatbot_service.get_reply(intent)
        return ChatbotResponse(intent=intent, reply=reply, confidence=confidence)
    except APIException as e:
        raise e # 重新拋出已處理的 APIException
    except Exception as e:
        logger.exception("Unexpected error in chatbot API.")
        raise APIException(status_code=500, message="Failed to process chatbot request.", code="CHATBOT_ERROR")
