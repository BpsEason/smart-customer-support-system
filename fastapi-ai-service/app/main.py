import os
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request, Response
from pydantic import BaseModel
import requests
import logging

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Import services
from app.services.chatbot_service import ChatbotService
from app.services.sentiment_service import SentimentService
from app.services.dispatch_service import DispatchService
from app.services.knowledge_base_service import KnowledgeBaseService

# Import models
from app.models.chatbot_models import ChatbotRequest, ChatbotResponse
from app.models.sentiment_models import SentimentRequest, SentimentResponse
from app.models.ticket_models import TicketAnalysisRequest, TicketAnalysisResponse, TicketDispatchResponse

app = FastAPI(
    title="Smart Customer Support AI Service",
    description="Provides AI capabilities for chatbot, sentiment analysis, and intelligent dispatch.",
    version="1.0.0"
)

# Initialize services (models will be loaded on demand or at startup)
chatbot_service = ChatbotService()
sentiment_service = SentimentService()
dispatch_service = DispatchService()
knowledge_base_service = KnowledgeBaseService()

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "ok", "message": "AI service is running"}

@app.post("/ai/chatbot", response_model=ChatbotResponse)
async def get_chatbot_reply(request: ChatbotRequest):
    """
    接收客戶訊息，進行意圖識別並生成聊天機器人回覆。
    """
    try:
        if not chatbot_service.is_model_loaded():
            raise HTTPException(status_code=503, detail="Chatbot model not loaded. Please train/load the model first.")

        intent, confidence = chatbot_service.predict_intent(request.message)
        reply = chatbot_service.get_reply(intent, request.message)
        logger.info(f"Chatbot - Message: '{request.message}', Intent: '{intent}', Reply: '{reply}'")
        return ChatbotResponse(intent=intent, reply=reply, confidence=confidence)
    except Exception as e:
        logger.error(f"Error in chatbot endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")

@app.post("/ai/sentiment", response_model=SentimentResponse)
async def analyze_sentiment(request: SentimentRequest):
    """
    對文本進行情感分析。
    """
    try:
        if not sentiment_service.is_model_loaded():
            raise HTTPException(status_code=503, detail="Sentiment model not loaded. Please train/load the model first.")

        sentiment, confidence = sentiment_service.analyze_sentiment(request.text)
        logger.info(f"Sentiment - Text: '{request.text}', Sentiment: '{sentiment}'")
        return SentimentResponse(sentiment=sentiment, confidence=confidence)
    except Exception as e:
        logger.error(f"Error in sentiment endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")

@app.post("/ai/dispatch_ticket", response_model=TicketDispatchResponse)
async def dispatch_ticket(request: TicketAnalysisRequest):
    """
    根據工單訊息進行智能分派。
    """
    try:
        if not chatbot_service.is_model_loaded():
            raise HTTPException(status_code=503, detail="Chatbot model not loaded for dispatch. Please train/load the model first.")

        # 首先進行意圖識別和情感分析
        intent, intent_confidence = chatbot_service.predict_intent(request.message)
        sentiment, sentiment_confidence = sentiment_service.analyze_sentiment(request.message)

        # 結合 AI 分析結果進行智能分派
        suggested_agent_id, suggested_priority = dispatch_service.suggest_dispatch(
            intent, sentiment, request.existing_ticket_status
        )

        logger.info(f"Dispatch - Ticket ID: {request.ticket_id}, Message: '{request.message}', Intent: '{intent}', Sentiment: '{sentiment}', Suggested Agent: {suggested_agent_id}, Suggested Priority: {suggested_priority}")

        return TicketDispatchResponse(
            ticket_id=request.ticket_id,
            intent=intent,
            intent_confidence=intent_confidence,
            sentiment=sentiment,
            sentiment_confidence=sentiment_confidence,
            suggested_agent_id=suggested_agent_id,
            suggested_priority=suggested_priority
        )
    except Exception as e:
        logger.error(f"Error in dispatch_ticket endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")

@app.post("/ai/process_incoming_message", response_model=TicketAnalysisResponse)
async def process_incoming_message(request: TicketAnalysisRequest):
    """
    統一處理來自 Laravel 的新進訊息，進行全面 AI 分析並生成自動回覆（如果適用）。
    """
    logger.info(f"Processing incoming message for ticket {request.ticket_id}: '{request.message}'")
    try:
        # Step 1: Sentiment Analysis
        sentiment, sentiment_confidence = "neutral", 0.0
        if sentiment_service.is_model_loaded():
            sentiment, sentiment_confidence = sentiment_service.analyze_sentiment(request.message)
            logger.info(f"Sentiment analysis: {sentiment} ({sentiment_confidence:.2f})")
        else:
            logger.warning("Sentiment model not loaded, skipping sentiment analysis.")

        # Step 2: Intent Recognition
        intent, intent_confidence = "unknown", 0.0
        if chatbot_service.is_model_loaded():
            intent, intent_confidence = chatbot_service.predict_intent(request.message)
            logger.info(f"Intent recognition: {intent} ({intent_confidence:.2f})")
        else:
            logger.warning("Chatbot model not loaded, skipping intent recognition.")

        # Step 3: Knowledge Base Search
        kb_answer = None
        if knowledge_base_service.is_kb_loaded():
            kb_answer = knowledge_base_service.search_knowledge_base(request.message, intent)
            if kb_answer:
                logger.info(f"Knowledge Base found answer: {kb_answer}")
            else:
                logger.info("No relevant answer found in knowledge base.")
        else:
            logger.warning("Knowledge base not loaded, skipping KB search.")

        # Step 4: Generate AI Reply (if applicable)
        ai_reply = None
        if kb_answer:
            ai_reply = kb_answer # If KB has a direct answer, use it
        elif intent != "unknown" and chatbot_service.is_model_loaded():
            # If a specific intent is recognized, try to get a canned/rule-based reply
            ai_reply = chatbot_service.get_reply(intent, request.message)
            if ai_reply:
                logger.info(f"Chatbot generated reply for intent '{intent}': {ai_reply}")
            else:
                logger.info(f"Chatbot has no specific reply for intent '{intent}'.")
        # else: Add integration with a Generative AI like OpenAI here
        # For example:
        # if not ai_reply and os.getenv("OPENAI_API_KEY"):
        #     try:
        #         from openai import OpenAI
        #         client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        #         chat_completion = client.chat.completions.create(
        #             model="gpt-3.5-turbo",
        #             messages=[
        #                 {"role": "system", "content": "You are a helpful customer support assistant."},
        #                 {"role": "user", "content": request.message}
        #             ]
        #         )
        #         ai_reply = chat_completion.choices[0].message.content
        #         logger.info(f"OpenAI generated reply: {ai_reply}")
        #     except Exception as e:
        #         logger.error(f"Error calling OpenAI API: {e}", exc_info=True)


        # Step 5: Intelligent Dispatch (Suggest status/agent)
        suggested_agent_id, suggested_priority = dispatch_service.suggest_dispatch(
            intent, sentiment, request.existing_ticket_status
        )
        logger.info(f"Suggested Dispatch - Agent: {suggested_agent_id}, Priority: {suggested_priority}")

        # Construct response
        response_data = TicketAnalysisResponse(
            ticket_id=request.ticket_id,
            sentiment=sentiment,
            sentiment_confidence=sentiment_confidence,
            intent=intent,
            intent_confidence=intent_confidence,
            ai_reply=ai_reply,
            suggested_agent_id=suggested_agent_id,
            suggested_priority=suggested_priority,
            knowledge_base_answer=kb_answer
        )
        return response_data

    except Exception as e:
        logger.error(f"Critical error processing incoming message for ticket {request.ticket_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")

@app.on_event("startup")
async def startup_event():
    """Load models at startup (optional, can also be on first request)."""
    logger.info("Attempting to load AI models at startup...")
    try:
        chatbot_service.load_model()
        sentiment_service.load_model()
        knowledge_base_service.load_knowledge_base()
        logger.info("AI models and knowledge base loaded successfully (if files exist).")
    except Exception as e:
        logger.warning(f"Could not load all AI models at startup: {e}")
        logger.warning("Please ensure models are trained and knowledge_base.json is in the correct volume.")

