import pytest
from app.services.chatbot_service import ChatbotService
from app.services.exceptions import ModelLoadingError, PredictionError, InvalidInputError
import os
import shutil

# 設置一個獨立的測試模型目錄，避免與實際應用衝突
TEST_MODEL_DIR = "test_models_chatbot"
TEST_KB_DIR = "test_data_chatbot" # 即使 KB 在單獨的 service，這裡也要確保不會衝突
TEST_KB_PATH = os.path.join(TEST_KB_DIR, "knowledge_base.json")

@pytest.fixture(scope="session", autouse=True)
def setup_and_teardown_env():
    """在所有測試開始前設定環境變數和清理目錄，在所有測試結束後清理。"""
    # 清理並創建測試目錄
    if os.path.exists(TEST_MODEL_DIR):
        shutil.rmtree(TEST_MODEL_DIR)
    os.makedirs(TEST_MODEL_DIR, exist_ok=True)

    if os.path.exists(TEST_KB_DIR):
        shutil.rmtree(TEST_KB_DIR)
    os.makedirs(TEST_KB_DIR, exist_ok=True)
    
    # 設置環境變數指向測試目錄
    os.environ["MODEL_DIR"] = TEST_MODEL_DIR
    os.environ["KNOWLEDGE_BASE_PATH"] = TEST_KB_PATH # 雖然不直接測試 KB，但確保環境變數指向正確

    # 在測試開始前執行一次模型訓練，避免每個測試函數都重新訓練
    # 這裡需要一個臨時的 ChatbotService 實例來觸發訓練
    temp_service = ChatbotService()
    temp_service._train_and_save_model() # 強制訓練並保存一次

    yield

    # 在所有測試完成後清理
    if os.path.exists(TEST_MODEL_DIR):
        shutil.rmtree(TEST_MODEL_DIR)
    if os.path.exists(TEST_KB_DIR):
        shutil.rmtree(TEST_KB_DIR)
    del os.environ["MODEL_DIR"]
    del os.environ["KNOWLEDGE_BASE_PATH"]

@pytest.fixture(scope="function")
def chatbot_service_instance():
    """為每個測試函數提供一個 ChatbotService 實例，確保其已初始化。"""
    # 由於 setup_and_teardown_env 已經觸發了訓練並保存到磁盤，
    # 這裡只需確保服務實例已初始化（會從磁盤加載）
    # 重置單例狀態，確保每次 fixture 獲取的是一個“freshly loaded”的服務
    ChatbotService._instance = None 
    ChatbotService._is_initialized = False
    return ChatbotService()

def test_chatbot_service_initialization(chatbot_service_instance):
    """測試服務初始化時模型是否被正確加載。"""
    assert chatbot_service_instance.model is not None
    assert chatbot_service_instance.vectorizer is not None
    assert os.path.exists(chatbot_service_instance.model_path)
    assert os.path.exists(chatbot_service_instance.vectorizer_path)
    print(f"Model path: {chatbot_service_instance.model_path}")
    print(f"Vectorizer path: {chatbot_service_instance.vectorizer_path}")

def test_predict_intent_password_reset(chatbot_service_instance):
    """測試密碼重置意圖的預測。"""
    intent, confidence = chatbot_service_instance.predict_intent("我忘記密碼了")
    assert intent == "password_reset"
    assert confidence > 0.5 # 確保有一定置信度

def test_predict_intent_order_status(chatbot_service_instance):
    """測試訂單狀態意圖的預測。"""
    intent, confidence = chatbot_service_instance.predict_intent("我的訂單到哪了？")
    assert intent == "order_status"
    assert confidence > 0.5

def test_predict_intent_transfer_to_agent(chatbot_service_instance):
    """測試轉接人工客服意圖的預測。"""
    intent, confidence = chatbot_service_instance.predict_intent("我需要人工客服")
    assert intent == "transfer_to_agent"
    assert confidence > 0.5

def test_predict_intent_general_inquiry(chatbot_service_instance):
    """測試通用查詢意圖的預測。"""
    intent, confidence = chatbot_service_instance.predict_intent("你好，請問有什麼能幫忙的嗎？")
    assert intent == "general_inquiry" # 應該會是通用查詢
    assert confidence > 0.1 # 泛化情況下，置信度可能不會很高，但應大於某個閾值

def test_predict_intent_new_phrase_for_existing_intent(chatbot_service_instance):
    """測試新語句對現有意圖的預測能力。"""
    intent, confidence = chatbot_service_instance.predict_intent("我的信用卡付款失敗了")
    assert intent == "billing_issue"
    assert confidence > 0.5

def test_predict_intent_empty_text_raises_error(chatbot_service_instance):
    """測試空文本輸入時是否拋出 PredictionError。"""
    with pytest.raises(PredictionError) as excinfo:
        chatbot_service_instance.predict_intent("")
    assert "Input text for prediction cannot be empty." in str(excinfo.value)

def test_predict_intent_whitespace_text_raises_error(chatbot_service_instance):
    """測試僅包含空白字符的文本輸入時是否拋出 PredictionError。"""
    with pytest.raises(PredictionError) as excinfo:
        chatbot_service_instance.predict_intent("   ")
    assert "Input text for prediction cannot be empty." in str(excinfo.value)

def test_get_reply_known_intent(chatbot_service_instance):
    """測試已知意圖的回覆。"""
    assert "密碼重置" in chatbot_service_instance.get_reply("password_reset")
    assert "訂單號碼" in chatbot_service_instance.get_reply("order_status")

def test_get_reply_unknown_intent(chatbot_service_instance):
    """測試未知意圖的回覆，應返回通用回覆。"""
    assert "無法理解" in chatbot_service_instance.get_reply("unrecognized_intent_xyz")
    assert "人工客服" in chatbot_service_instance.get_reply("unrecognized_intent_xyz")

# 可以添加更多測試用例來覆蓋：
# - 模型重新訓練邏輯 (例如，刪除模型文件後再初始化服務)
# - 大量輸入文本的性能測試 (如果需要)
# - 邊緣情況的輸入 (例如，特殊字符，非常長的文本)
