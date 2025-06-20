import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import os
import json

# Adjust path for import if running directly or via pytest
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../')))
from app.main import app

client = TestClient(app)

# Mock environment variables for testing
@pytest.fixture(autouse=True)
def mock_env_vars():
    with patch.dict(os.environ, {
        "MODEL_PATH_CHATBOT": "/tmp/test_chatbot_model.joblib",
        "MODEL_PATH_SENTIMENT": "/tmp/test_sentiment_model.joblib",
        "KNOWLEDGE_BASE_PATH": "/tmp/test_knowledge_base.json",
        "LARAVEL_BACKEND_URL": "http://mock-laravel:9000",
        "DEBUG_MODE": "True"
    }):
        yield

@pytest.fixture(autouse=True)
def setup_test_files():
    # Create dummy model files
    dummy_pipeline = MagicMock()
    dummy_pipeline.named_steps.clf.classes_ = ['greeting', 'password_reset', 'unknown']
    dummy_pipeline.predict.return_value = ['greeting']
    dummy_pipeline.decision_function.return_value = [[1.5, 0.1, 0.0]] # Scores for confidence
    with patch('joblib.dump') as mock_dump:
        # Simulate training saving the model
        chatbot_service = app.dependency_overrides.get(app.router.routes[0].endpoint, MagicMock()).chatbot_service
        if chatbot_service and hasattr(chatbot_service, '_train_and_save_model'):
             chatbot_service._train_and_save_model(
                 ['hello', 'reset my password'],
                 ['greeting', 'password_reset'],
                 os.getenv("MODEL_PATH_CHATBOT")
             )
        else:
            joblib.dump(dummy_pipeline, os.getenv("MODEL_PATH_CHATBOT"))
    
    sentiment_pipeline = MagicMock()
    sentiment_pipeline.named_steps.clf.classes_ = ['positive', 'negative', 'neutral']
    sentiment_pipeline.predict.return_value = ['positive']
    sentiment_pipeline.decision_function.return_value = [[2.0, -1.0, 0.0]] # Scores for confidence
    with patch('joblib.dump') as mock_dump:
        sentiment_service = app.dependency_overrides.get(app.router.routes[0].endpoint, MagicMock()).sentiment_service
        if sentiment_service and hasattr(sentiment_service, '_train_and_save_model'):
            sentiment_service._train_and_save_model(
                ['I love this', 'I hate this'],
                ['positive', 'negative'],
                os.getenv("MODEL_PATH_SENTIMENT")
            )
        else:
            joblib.dump(sentiment_pipeline, os.getenv("MODEL_PATH_SENTIMENT"))

    # Create dummy knowledge base file
    kb_data = [
        {"question": "How to reset password?", "answer": "You can reset your password on the login page.", "intent_keyword": "password_reset"},
        {"question": "What is my order status?", "answer": "Please provide your order number to check status.", "intent_keyword": "order_status"}
    ]
    with open(os.getenv("KNOWLEDGE_BASE_PATH"), 'w', encoding='utf-8') as f:
        json.dump(kb_data, f)
    
    # Reload services to pick up the mocked files
    app.dependency_overrides[app.on_event("startup")] = MagicMock() # Temporarily disable real startup to avoid re-loading
    with patch('app.services.chatbot_service.load_model_from_path', return_value=dummy_pipeline), \
         patch('app.services.sentiment_service.load_model_from_path', return_value=sentiment_pipeline):
        
        # Manually trigger model loading for tests
        app.chatbot_service = app.services.chatbot_service.ChatbotService()
        app.sentiment_service = app.services.sentiment_service.SentimentService()
        app.knowledge_base_service = app.services.knowledge_base_service.KnowledgeBaseService()
        app.dispatch_service = app.services.dispatch_service.DispatchService()
        
    yield
    # Cleanup dummy files
    if os.path.exists(os.getenv("MODEL_PATH_CHATBOT")):
        os.remove(os.getenv("MODEL_PATH_CHATBOT"))
    if os.path.exists(os.getenv("MODEL_PATH_SENTIMENT")):
        os.remove(os.getenv("MODEL_PATH_SENTIMENT"))
    if os.path.exists(os.getenv("KNOWLEDGE_BASE_PATH")):
        os.remove(os.getenv("KNOWLEDGE_BASE_PATH"))

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "message": "AI service is running"}

def test_get_chatbot_reply():
    response = client.post("/ai/chatbot", json={"message": "Hello"})
    assert response.status_code == 200
    data = response.json()
    assert "intent" in data
    assert "reply" in data
    assert "confidence" in data
    assert data["intent"] == "greeting"
    assert data["reply"] == "Hello! How can I assist you today?"
    assert data["confidence"] > 0

def test_analyze_sentiment():
    response = client.post("/ai/sentiment", json={"text": "This is great!"})
    assert response.status_code == 200
    data = response.json()
    assert "sentiment" in data
    assert "confidence" in data
    assert data["sentiment"] == "positive"
    assert data["confidence"] > 0

def test_dispatch_ticket():
    response = client.post("/ai/dispatch_ticket", json={
        "ticket_id": 123,
        "message": "My internet is not working. I need technical support.",
        "customer_id": 1,
        "existing_ticket_status": "pending"
    })
    assert response.status_code == 200
    data = response.json()
    assert "intent" in data
    assert "sentiment" in data
    assert "suggested_agent_id" in data
    assert "suggested_priority" in data
    assert data["intent"] == "technical_support" # Based on mock data
    assert data["sentiment"] == "neutral" # Based on mock data
    assert data["suggested_agent_id"] == 1 # Based on mock dispatch logic for tech support
    assert data["suggested_priority"] == "normal" # Default from neutral

def test_process_incoming_message_with_ai_reply_from_kb():
    response = client.post("/ai/process_incoming_message", json={
        "ticket_id": 456,
        "message": "I forgot my password, how to reset it?",
        "customer_id": 2,
        "existing_ticket_status": "pending"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "password_reset"
    assert data["ai_reply"] == "You can reset your password on the login page."
    assert data["knowledge_base_answer"] == "You can reset your password on the login page."
    assert data["suggested_priority"] == "normal" # default for neutral sentiment

def test_process_incoming_message_no_ai_reply_needs_agent():
    # Simulate a message that AI doesn't have a direct answer for
    response = client.post("/ai/process_incoming_message", json={
        "ticket_id": 789,
        "message": "I have a very unique problem that needs expert help.",
        "customer_id": 3,
        "existing_ticket_status": "pending"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "unknown" # Or some fallback intent
    assert data["ai_reply"] is None # No AI reply
    assert data["suggested_priority"] == "normal" # Default from neutral
    assert data["suggested_agent_id"] == 3 # Default to admin if no specific agent
