# 智慧型客服與支援系統

## 專案概述

本專案是一個基於微服務架構的智慧型客服系統，整合 **Laravel** 後端與 **FastAPI** AI 服務，旨在提升客戶支持效率與體驗。系統通過 AI 驅動的聊天機器人、情感分析、智能工單分配和知識庫推薦，實現多渠道（Web、App、Email）客戶互動，並利用 **Redis** 佇列與 **WebSocket** 確保實時性和可擴展性。

本專案展示了一個高併發、AI 驅動的現代化客服解決方案，適用於企業級應用，特別適合需要快速響應和智能自動化的場景。

## 核心功能與亮點

- **微服務架構**：Laravel 負責工單管理與 WebSocket 通信，FastAPI 提供 AI 功能，模塊化設計便於獨立部署和維護。
- **AI 驅動客服**：利用 NLP 模型實現意圖識別、情感分析和智能工單分配，減少人工干預。
- **實時通信**：通過 **Laravel Reverb** 實現低延遲的 WebSocket 通信，提升用戶體驗。
- **非同步處理**：採用 **Redis** 佇列處理 AI 分析和郵件發送，確保高吞吐量。
- **數據持久化**：使用 Docker Volume 持久化 AI 模型和知識庫數據，保證服務穩定性。
- **安全與監控**：整合 API 認證、日誌記錄和儀表板分析，確保系統安全與可追蹤性。

## 技術亮點展示

以下是系統核心功能的代碼片段，展示關鍵技術實現：

### 1. Webhook 處理（Laravel）
接收來自多渠道的客戶訊息，並通過 Redis 佇列非同步處理：

```php
// laravel-backend/app/Http/Controllers/WebhookController.php
public function handleIncoming(Request $request)
{
    Log::info('Received incoming webhook:', $request->all());
    
    $request->validate([
        'message' => 'required|string|max:5000',
        'customer_identifier' => 'required|string|max:255',
        'source_channel' => 'required|string|in:web_chat,email,line_webhook,other',
        'subject' => 'nullable|string|max:255',
    ]);

    $customer = User::firstOrCreate(
        ['email' => $request->input('customer_identifier')],
        ['name' => 'External Customer', 'password' => Str::random(10), 'role' => 'customer']
    );

    $ticket = Ticket::where('customer_id', $customer->id)
                    ->whereIn('status', ['pending', 'in_progress', 'replied'])
                    ->orderBy('updated_at', 'desc')
                    ->first() ?? Ticket::create([
                        'customer_id' => $customer->id,
                        'subject' => $request->input('subject', 'New Inquiry from ' . $request->input('source_channel')),
                        'status' => 'pending',
                        'priority' => 'normal',
                        'source_channel' => $request->input('source_channel'),
                    ]);

    ProcessIncomingWebhook::dispatch(
        $ticket->id,
        $request->input('message'),
        $customer->id,
        $request->input('source_channel')
    );

    return response()->json(['status' => 'Message received and queued for processing.'], 202);
}
```

### 2. AI 訊息處理（FastAPI）
處理客戶訊息，進行情感分析、意圖識別並生成回覆：

```python
# fastapi-ai-service/app/main.py
@app.post("/ai/process_incoming_message", response_model=TicketAnalysisResponse)
async def process_incoming_message(request: TicketAnalysisRequest):
    logger.info(f"Processing incoming message for ticket {request.ticket_id}: '{request.message}'")
    
    sentiment, sentiment_confidence = "neutral", 0.0
    if sentiment_service.is_model_loaded():
        sentiment, sentiment_confidence = sentiment_service.analyze_sentiment(request.message)

    intent, intent_confidence = "unknown", 0.0
    if chatbot_service.is_model_loaded():
        intent, intent_confidence = chatbot_service.predict_intent(request.message)

    kb_answer = None
    if knowledge_base_service.is_kb_loaded():
        kb_answer = knowledge_base_service.search_knowledge_base(request.message, intent)

    ai_reply = kb_answer or (chatbot_service.get_reply(intent, request.message) if intent != "unknown" else None)
    
    suggested_agent_id, suggested_priority = dispatch_service.suggest_dispatch(
        intent, sentiment, request.existing_ticket_status
    )

    return TicketAnalysisResponse(
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
```

### 3. WebSocket 實時通信（Laravel）
通過 Laravel Reverb 廣播工單回覆，實現實時更新：

```php
// laravel-backend/app/Events/MessageReplied.php
class MessageReplied implements ShouldBroadcast
{
    public $ticket;
    public $reply;

    public function __construct(Ticket $ticket, Reply $reply)
    {
        $this->ticket = $ticket;
        $this->reply = $reply;
    }

    public function broadcastOn(): array
    {
        return [new PrivateChannel('tickets.' . $this->ticket->id)];
    }

    public function broadcastAs(): string
    {
        return 'message.replied';
    }

    public function broadcastWith(): array
    {
        return [
            'ticket_id' => $this->ticket->id,
            'reply' => $this->reply->load('user'),
        ];
    }
}
```

## 系統架構

以下是系統架構圖，展示組件間的數據流與交互：

```mermaid
graph TD
    A[用戶] -->|發送請求| B(Web 客戶端)
    B -->|Webhook 輸入| C[Webhook 接收器]
    C -->|推送到佇列| D[Redis 佇列]
    D -->|分發至 AI| E[FastAPI AI 服務]
    E -->|處理結果| D
    D -->|更新工單| F[工單系統]
    F -->|儲存數據| G[MySQL 資料庫]
    F -->|推送回覆| H[WebSocket 服務]
    H -->|實時更新| B
    I[管理員介面] -->|API 操作| F
    J[儀表板] -->|監控數據| F

    subgraph 客戶介面
        A
        B
    end

    subgraph Laravel 後端
        C
        D
        F
        G
        H
        I
        J
    end

    subgraph AI 服務
        E
        E -->|意圖識別| E1[聊天機器人]
        E -->|情感分析| E2[情感分析]
        E -->|工單分配| E3[智能分配]
        E -->|知識查詢| E4[知識庫]
        E1 -->|NLP 模型| E5[NLP 模型]
        E2 -->|AI 模型| E6[AI 模型]
        E4 -->|數據存儲| E7[知識庫數據]
    end

    style A fill:#f9f,stroke:#333
    style B fill:#bbf,stroke:#333
    style C fill:#dfd,stroke:#333
    style D fill:#ffb,stroke:#333
    style E fill:#e6e,stroke:#333
    style F fill:#ddf,stroke:#333
    style G fill:#dfd,stroke:#333
    style H fill:#dfd,stroke:#333
    style I fill:#dfd,stroke:#333
    style J fill:#dfd,stroke:#333
    style E1 fill:#e6e,stroke:#333
    style E2 fill:#e6e,stroke:#333
    style E3 fill:#e6e,stroke:#333
    style E4 fill:#e6e,stroke:#333
    style E5 fill:#e6e,stroke:#333
    style E6 fill:#e6e,stroke:#333
    style E7 fill:#e6e,stroke:#333
```

### 架構說明

- **客戶介面**：
  - 用戶通過 Web 客戶端發送請求，Webhook 接收器處理多渠道（Web、App、Email）輸入。
- **Laravel 後端**：
  - **Webhook 接收器**：接收並驗證客戶訊息，推送到 Redis 佇列。
  - **工單系統**：管理工單生命週期，與 MySQL 資料庫同步數據。
  - **WebSocket 服務**：通過 Laravel Reverb 實現實時回覆推送。
  - **管理員介面**：提供 API 驅動的操作介面。
  - **儀表板**：顯示監控數據，支援系統管理。
- **FastAPI AI 服務**：
  - 提供意圖識別（聊天機器人）、情感分析、智能工單分配和知識庫推薦。
  - 使用 NLP 模型和 AI 模型進行分析，持久化 Volume 存儲知識庫數據。
- **數據流**：
  - 訊息從 Web 客戶端經 Webhook 接收器進入 Redis 佇列。
  - Redis 佇列將訊息分發至 FastAPI AI 服務進行處理（包括意圖識別、情感分析等）。
  - 處理結果回傳至 Redis 佇列，更新工單系統。
  - 工單系統通過 WebSocket 服務將回覆實時推送給 Web 客戶端。

## 技術挑戰與解決方案

1. **高併發**：使用 Redis 佇列和 Docker 容器化，確保系統在高峰期穩定運行。
2. **AI 整合**：通過 FastAPI 提供高效 API，持久化 Volume 存儲模型，降低延遲。
3. **實時通信**：採用 Laravel Reverb 實現低延遲 WebSocket，減少外部服務依賴。
4. **數據一致性**：結合 MySQL 和 Redis 雙緩存，確保工單狀態與 AI 分析同步。

## 快速入門

### 環境要求

- Docker & Docker Compose
- PHP 8.3+
- Python 3.10+
- MySQL 8.0+
- Redis

### 安裝與運行

1. 克隆專案並進入目錄：
   ```bash
   git clone https://github.com/BpsEason/smart-customer-support-system.git
   cd smart-customer-support-system
   ```

2. **配置環境變數**：
   - 複製並編輯 Laravel 環境文件：
     ```bash
     cp laravel-backend/.env.example laravel-backend/.env
     ```
     修改 `DB_PASSWORD`、`APP_KEY` 和 Reverb 相關配置（如 `REVERB_APP_ID`）。
   - 複製並編輯 FastAPI 環境文件：
     ```bash
     cp fastapi-ai-service/.env.example fastapi-ai-service/.env
     ```
     配置 AI 相關變數（如 `OPENAI_API_KEY`，若適用）。

3. **訓練 AI 模型**（首次運行）：
   - 準備訓練數據（CSV 或 JSON 格式），示例：
     ```csv
     text,intent
     "Hello",greeting
     "Forgot my password",password_reset
     ```
     ```csv
     text,sentiment
     "I love this product",positive
     "This is terrible",negative
     ```
   - 將數據保存至 `fastapi-ai-service/app/data/`。
   - 運行訓練命令：
     ```bash
     docker compose run --rm fastapi-ai python -c "from app.services.chatbot_service import ChatbotService; ChatbotService()._train_and_save_model(open('/app/data/training_chatbot.csv').read().splitlines(), open('/app/data/training_intent.csv').read().splitlines(), '/app/models_data/trained_chatbot_model.joblib')"
     ```
     ```bash
     docker compose run --rm fastapi-ai python -c "from app.services.sentiment_service import SentimentService; SentimentService()._train_and_save_model(open('/app/data/training_sentiment.csv').read().splitlines(), open('/app/data/training_sentiment.csv').read().splitlines(), '/app/models_data/trained_sentiment_model.joblib')"
     ```

4. **複製知識庫數據**：
   ```bash
   cp fastapi-ai-service/app/data/knowledge_base.json knowledge_data/knowledge_base.json
   ```

5. 啟動服務：
   ```bash
   docker compose up --build -d
   ```

6. 運行 Laravel 資料庫遷移：
   ```bash
   docker compose exec php-fpm php artisan migrate
   ```

7. （可選）填充測試數據：
   ```bash
   docker compose exec php-fpm php artisan db:seed
   ```

8. 訪問應用：
   - 前端：`http://localhost`
   - FastAPI 文檔：`http://localhost:8001/docs`

### 注意事項

- **管理後台**：目前無預設圖形化管理後台，需通過 API 操作或自行開發（參見下節）。
- **訓練數據**：確保數據集包含足夠的多樣化樣本（建議 100-1000 條記錄）以提升模型準確性。

## 開發管理後台

為提升管理員體驗，可開發基於 **Vue.js** 的圖形化後台。以下是建議步驟：

1. **初始化 Vue 項目**：
   ```bash
   cd laravel-backend
   npm create vue@latest
   ```

2. **設置路由與組件**：
   - 創建 `admin/src/views/TicketList.vue` 等組件。
   - 配置路由（如 `/admin/tickets`）。

3. **集成 Laravel API**：
   使用 Axios 調用 API（如 `/api/tickets`），示例：
   ```javascript
   // admin/src/views/TicketList.vue
   import axios from 'axios';

   export default {
     data() {
       return { tickets: [] };
     },
     async created() {
       const token = localStorage.getItem('token');
       const response = await axios.get('http://localhost/api/tickets', {
         headers: { Authorization: `Bearer ${token}` },
       });
       this.tickets = response.data;
     },
   };
   ```

4. **部署後台**：
   - 將構建後的靜態文件放至 `laravel-backend/public/admin/`。
   - 更新 Nginx 配置，添加 `/admin/` 路由。

## 管理員操作指引

管理員需通過 API 進行操作：

1. **註冊管理員**：
   ```bash
   curl -X POST http://localhost/api/register \
   -H "Content-Type: application/json" \
   -d '{"name":"Admin User","email":"admin@example.com","password":"your_password","password_confirmation":"your_password","role":"admin"}'
   ```

2. **登錄獲取令牌**：
   ```bash
   curl -X POST http://localhost/api/login \
   -H "Content-Type: application/json" \
   -d '{"email":"admin@example.com","password":"your_password"}'
   ```

3. **查詢工單**：
   ```bash
   curl -X GET http://localhost/api/tickets \
   -H "Authorization: Bearer YOUR_TOKEN"
   ```

## 測試運行

1. **Laravel 測試**：
   ```bash
   docker compose exec php-fpm vendor/bin/phpunit
   ```

2. **FastAPI 測試**：
   ```bash
   docker compose exec fastapi-ai pytest tests/
   ```

## 未來改進

- 整合多語言情感分析模型。
- 使用更高級的 NLP 模型（如 BERT）提升意圖識別準確性。
- 實現故障轉移和高可用性機制。
- 開發完整的圖形化管理後台。

## 許可證

採用 [MIT 許可證](LICENSE).
