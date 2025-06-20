import os
import logging
from typing import Tuple, List, Optional
from fastapi import FastAPI, HTTPException, status, Depends
from pydantic import BaseModel, Field

# 假設這些服務文件已存在於 app/services
from app.services.chatbot_service import ChatbotService
from app.services.sentiment_service import SentimentService
from app.services.dispatch_service import DispatchService
from app.services.knowledge_base_service import KnowledgeBaseService

# 設定日誌
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="智能客服 AI 服務",
    description="提供聊天機器人、情感分析、智能工單分派、知識庫推薦等 AI 功能。",
    version="0.1.0",
)

class ProcessMessageRequest(BaseModel):
    message: str = Field(..., description="客戶發送的原始訊息內容")
    customer_id: str = Field(..., description="客戶的唯一識別符 (例如 Email)")
    source: str = Field("web_chat", description="訊息來源渠道 (例如 web_chat, email, line_webhook)")
    api_key: Optional[str] = Field(None, description="API 認證金鑰")

class AIResponse(BaseModel):
    status: str = Field("success", description="處理狀態")
    intent: Optional[str] = Field(None, description="識別出的用戶意圖")
    intent_confidence: Optional[float] = Field(None, description="意圖識別的置信度")
    chatbot_reply: Optional[str] = Field(None, description="AI 聊天機器人給出的建議回覆")
    sentiment: Optional[str] = Field(None, description="訊息情感分類 (positive, neutral, negative)")
    sentiment_score: Optional[float] = Field(None, description="情感分析的置信度")
    assigned_agent: Optional[str] = Field(None, description="建議分派的客服或部門")
    knowledge_suggestions: Optional[List[dict]] = Field(None, description="相關知識庫文章建議")
    process_details: Optional[str] = Field(None, description="處理細節或備註")

# 簡易的 API 金鑰認證依賴
def verify_api_key(api_key: str = Depends(ProcessMessageRequest.api_key)):
    expected_api_key = os.getenv("AI_SERVICE_API_KEY")
    if expected_api_key and api_key != expected_api_key:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid API Key")
    return api_key

@app.get("/", tags=["Health Check"])
async def read_root():
    return {"message": "智能客服 AI 服務運行中！"}

@app.post("/ai/process_message", response_model=AIResponse, summary="統一處理 incoming 訊息並返回 AI 分析結果")
async def process_incoming_message(request: ProcessMessageRequest, api_key: str = Depends(verify_api_key)):
    logger.info(f"Received message for processing: {request.customer_id} - {request.message} (Source: {request.source})")
    try:
        # 1. 意圖識別 / 聊天機器人回覆
        chatbot_service = ChatbotService()
        predicted_intent, confidence = chatbot_service.predict_intent(request.message)
        chatbot_reply = chatbot_service.get_reply(predicted_intent, request.message) # 傳入原始訊息以便於更智能的回覆

        # 2. 情感分析
        sentiment_service = SentimentService()
        sentiment_label, sentiment_score = sentiment_service.analyze_sentiment(request.message)

        # 3. 智能工單分派
        dispatch_service = DispatchService()
        assigned_agent = dispatch_service.dispatch_ticket(
            request.message,
            sentiment_label,
            predicted_intent
        )

        # 4. 知識庫推薦
        knowledge_base_service = KnowledgeBaseService()
        kb_suggestions = knowledge_base_service.search_knowledge_base(predicted_intent, request.message)


        return AIResponse(
            status="success",
            intent=predicted_intent,
            intent_confidence=confidence,
            chatbot_reply=chatbot_reply,
            sentiment=sentiment_label,
            sentiment_score=sentiment_score,
            assigned_agent=assigned_agent,
            knowledge_suggestions=kb_suggestions,
            process_details="AI 分析完成並生成回覆"
        )
    except Exception as e:
        logger.error(f"Error processing message: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI processing failed: {e}"
        )
