from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn
import logging
from dotenv import load_dotenv
import os

# 載入環境變數
load_dotenv()

# 導入 AI 模組和服務層
from app.api import chatbot_api, sentiment_api, dispatch_api, knowledge_base_api
from app.services.exceptions import APIException # 導入自定義異常

# 配置日誌
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="智能客服AI服務",
    description="提供聊天機器人、情感分析、智能分派和知識庫推薦功能。",
    version="1.0.0",
)

# 異常處理器
@app.exception_handler(APIException)
async def api_exception_handler(request: Request, exc: APIException):
    logger.error(f"API Exception caught: Code={exc.code}, Message={exc.message}", exc_info=True)
    return JSONResponse(
        status_code=exc.status_code,
        content={"message": exc.message, "code": exc.code},
    )

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    logger.error(f"HTTP Exception caught: Status={exc.status_code}, Detail={exc.detail}", exc_info=True)
    return JSONResponse(
        status_code=exc.status_code,
        content={"message": exc.detail, "code": f"HTTP_{exc.status_code}"},
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled exception occurred:")
    return JSONResponse(
        status_code=500,
        content={"message": "An unexpected internal server error occurred.", "code": "SERVER_ERROR"},
    )

# 導入各個 AI 功能的路由
app.include_router(chatbot_api.router, prefix="/ai/chatbot", tags=["Chatbot"])
app.include_router(sentiment_api.router, prefix="/ai/sentiment", tags=["Sentiment Analysis"])
app.include_router(dispatch_api.router, prefix="/ai/dispatch", tags=["Intelligent Dispatch"])
app.include_router(knowledge_base_api.router, prefix="/ai/knowledge", tags=["Knowledge Base"])

class MessageRequest(BaseModel):
    message: str
    customer_id: str
    source: str = "unknown"

class AIProcessResponse(BaseModel):
    intent: str
    sentiment: str
    suggested_reply: str | None = None
    recommended_agent_id: int | None = None
    ticket_category: str
    knowledge_base_match: list | None = None

@app.get("/")
async def read_root():
    return {"message": "智能客服AI服務運行中！訪問 /docs 查看 API 文檔。"}

@app.post("/ai/process_message", response_model=AIProcessResponse)
async def process_incoming_message(request: MessageRequest):
    """
    統一處理來自 Laravel 的進站訊息，並進行多重 AI 分析。
    """
    logger.info(f"Processing incoming message from customer {request.customer_id}: {request.message[:100]}...")

    try:
        # 1. 聊天機器人意圖識別與初步回覆
        chatbot_response = await chatbot_api.get_chatbot_response(chatbot_api.ChatbotRequest(text=request.message))
        intent = chatbot_response.intent
        suggested_reply = chatbot_response.reply

        # 2. 情感分析
        sentiment_response = await sentiment_api.get_sentiment(sentiment_api.SentimentRequest(text=request.message))
        sentiment_label = sentiment_response.sentiment

        # 3. 智能工單分派
        dispatch_response = await dispatch_api.dispatch_customer_ticket(
            dispatch_api.DispatchRequest(
                message=request.message,
                intent=intent,
                sentiment=sentiment_label
            )
        )
        recommended_agent_id = dispatch_response.recommended_agent_id
        ticket_category = dispatch_response.category

        # 4. 知識庫推薦
        knowledge_matches_response = await knowledge_base_api.get_knowledge_recommendations(knowledge_base_api.KnowledgeSearchRequest(query=request.message))
        knowledge_matches = knowledge_matches_response.matches

        return AIProcessResponse(
            intent=intent,
            sentiment=sentiment_label,
            suggested_reply=suggested_reply,
            recommended_agent_id=recommended_agent_id,
            ticket_category=ticket_category,
            knowledge_base_match=knowledge_matches
        )

    except APIException as e:
        logger.error(f"API Exception during AI message processing: {e.message}", exc_info=True)
        raise e # 重新拋出，由 @app.exception_handler(APIException) 處理
    except Exception as e:
        logger.exception("Unexpected error during AI message processing.")
        raise HTTPException(status_code=500, detail="Internal AI service error.")

# 你可以獨立運行這個 FastAPI 應用
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
