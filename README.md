# 智慧型客服與支援系統

## 專案概覽
這是一個基於微服務架構的智慧型客服系統，整合 Laravel 後端與 FastAPI AI 服務，旨在提升客戶支持效率與體驗。系統通過 AI 驅動的聊天機器人、情感分析、智能工單分配和知識庫推薦，實現多渠道（Web、App、Email）客戶互動，並透過 Redis 佇列與 WebSocket 確保實時性與可擴展性。本專案展現了對高併發、數據處理與 AI 整合的專業解決方案設計。

## 核心技術與亮點
- **微服務架構**: 分離 Laravel 後端（工單管理、WebSocket）與 FastAPI AI 服務（AI 功能），實現模塊化與獨立部署。
- **AI 驅動**: 利用 NLP 模型進行意圖識別與回覆生成，結合情感分析與智能分配，減少人工干預。
- **非同步處理**: 採用 Redis 佇列處理 AI 分析與郵件發送，確保系統在高峰期仍具高吞吐量。
- **實時互動**: 通過 Laravel Reverb 與 WebSocket 實現低延遲客戶回覆，優化用戶體驗。
- **數據持久化**: 使用 Docker Volume 持久化 AI 模型與知識庫數據，確保服務穩定性。
- **安全與監控**: 整合 API 金鑰驗證與日誌記錄，支援管理員儀表板分析。

## 系統架構與詳細說明
以下架構圖展示系統組件與數據流向，體現模塊化設計與高效交互：

```mermaid
graph TD
    subgraph 客戶介面 - Web / App / Email
        User[用戶 / 客戶] --> WebApp["前端應用 (Web/APP)"]
        WebApp --> WebhookReceiver[Laravel Webhook 接收器]
    end

    subgraph Laravel 後端服務
        WebhookReceiver --> RedisQueue["Redis 佇列 (非同步任務)"]
        TicketSystem[工單系統] -- 數據庫操作 --> MySQL[MySQL 資料庫]
        TicketSystem -- 數據同步/分析 --> Dashboard[儀表板]
        TicketSystem -- Webhook/Email/WebSocket --> WebApp
        RedisQueue -- "處理排隊任務 (如 AI 分析、郵件發送)" --> TicketSystem
        AdminAgentInterface[管理員/客服介面] -- 管理工單/用戶 --> TicketSystem
    end

    subgraph FastAPI AI 服務
        RedisQueue -- "AI 請求 (透過 Laravel)" --> FastAPIAPI[FastAPI AI 服務]
        FastAPIAPI --> Chatbot[聊天機器人]
        FastAPIAPI --> SentimentAnalysis[情緒分析]
        FastAPIAPI --> IntelligentDispatch[智能工單分配]
        FastAPIAPI --> KnowledgeBase[知識庫推薦]
        Chatbot -- 依賴 --> NLPModel["NLP 模型 (持久化 Volume)"]
        SentimentAnalysis -- 依賴 --> AIModelFiles["AI 模型檔 (持久化 Volume)"]
        KnowledgeBase -- 依賴 --> KBData["知識庫數據 (持久化 Volume)"]
    end

    FastAPIAPI -- "返回處理結果 (含 AI 回覆)" --> RedisQueue
    RedisQueue -- "更新工單/觸發回覆" --> TicketSystem

    %% 關鍵：明確的客戶回覆路徑
    TicketSystem -- "AI/人工回覆 (Email/WebSocket/IM API)" --> WebApp
    WebApp -- "顯示回覆" --> User

    style User fill:#f9f,stroke:#333,stroke-width:2px
    style WebApp fill:#bbf,stroke:#333,stroke-width:2px
    style WebhookReceiver fill:#cfe,stroke:#333,stroke-width:2px
    style RedisQueue fill:#ffb,stroke:#333,stroke-width:2px
    style FastAPIAPI fill:#e6e,stroke:#333,stroke-width:2px
    style Chatbot fill:#fcf,stroke:#333,stroke-width:1px
    style SentimentAnalysis fill:#fcf,stroke:#333,stroke-width:1px
    style IntelligentDispatch fill:#fcf,stroke:#333,stroke-width:1px
    style KnowledgeBase fill:#fcf,stroke:#333,stroke-width:1px
    style NLPModel fill:#add8e6,stroke:#333,stroke-width:1px
    style AdminAgentInterface fill:#cff,stroke:#333,stroke-width:2px
    style Dashboard fill:#cfe,stroke:#333,stroke-width:2px
```

### 架構詳細說明
- **客戶介面**: 前端應用（Web/APP）負責用戶交互，通過 Webhook 將訊息傳至 Laravel 後端，支援多渠道輸入。
- **Laravel 後端服務**: 
  - `WebhookReceiver` 接收並驗證客戶訊息，推送至 `RedisQueue` 進行非同步處理。
  - `TicketSystem` 管理工單生命週期，與 MySQL 存儲數據，通過 WebSocket 與前端實時同步。
  - `AdminAgentInterface` 提供管理員與客服的操作介面，整合 `Dashboard` 進行數據分析（目前僅支援 API 訪問，無預設圖形化介面）。
- **FastAPI AI 服務**: 
  - `FastAPIAPI` 作為 AI 核心，提供聊天回覆、情感分析、工單分配與知識庫推薦。
  - 依賴持久化 Volume 存儲 `NLPModel`、`AIModelFiles` 和 `KBData`，確保模型與數據可復用。
- **數據流**: 訊息經 Redis 佇列分發至 AI 服務，處理結果反饋至工單系統，最終通過適當渠道（如 WebSocket）回傳用戶。

## 技術挑戰與解決方案
1. **高併發處理**: 通過 Redis 佇列實現任務非同步化，結合 Docker 容器化提升擴展性。
2. **AI 模型整合**: 設計了持久化 Volume 儲存模型文件，並通過 FastAPI 提供高效 API 接口，確保低延遲回應。
3. **實時通信**: 使用 Laravel Reverb 替代傳統 Pusher，減少依賴外部服務並優化成本。
4. **數據一致性**: 實施 MySQL 與 Redis 雙緩存策略，確保工單狀態與 AI 分析結果同步。

## 專業貢獻
- **架構設計**: 主導微服務分層，實現高內聚低耦合的系統結構。
- **AI 實現**: 開發了基於 Scikit-learn 的 NLP 模型訓練與部署流程，結合 FastAPI 優化 API 性能。
- **可擴展性**: 設計了模塊化代碼與 Docker Compose 配置，支持多環境部署。
- **監控與優化**: 整合日誌系統與儀表板，支援實時性能分析與問題排查。

## 快速入門
### 環境要求
- Docker
- Docker Compose
- PHP 8.3+
- Python 3.10+
- MySQL 8.0+
- Redis

### 啟動專案
1. 進入專案目錄：`cd smart-customer-support-system`
2. **重要**: 編輯環境變數文件。
   - 將 `laravel-backend/.env.example` 複製為 `laravel-backend/.env`（`cp laravel-backend/.env.example laravel-backend/.env`），並修改敏感資訊（如 `DB_PASSWORD` 和 `APP_KEY`）。
   - 將 `fastapi-ai-service/.env.example` 複製為 `fastapi-ai-service/.env`（`cp fastapi-ai-service/.env.example fastapi-ai-service/.env`），配置 AI 相關變數（如 `OPENAI_API_KEY`，若適用）。
   - 腳本會自動生成隨機密碼和 Reverb 配置，請保存輸出中的值並填入 `.env` 文件。
3. **AI 模型訓練 (首次運行或模型更新)**:
   - 準備訓練數據：AI 模型需要結構化的文本數據集（推薦格式為 CSV 或 JSON）。例如：
     - **Chatbot 模型**: 包含 `text`（用戶訊息）和 `intent`（意圖標籤）列，例如：
       ```csv
       text,intent
       "Hello",greeting
       "Forgot my password",password_reset
       "Order status",order_status
       ```
     - **Sentiment 模型**: 包含 `text`（文本）和 `sentiment`（情感標籤，如 `positive`、`negative`、`neutral`）列，例如：
       ```csv
       text,sentiment
       "I love this product",positive
       "This is terrible",negative
       "It's okay",neutral
       ```
   - 將數據文件保存到 `fastapi-ai-service/app/data/` 目錄（例如 `training_chatbot.csv` 和 `training_sentiment.csv`）。
   - 運行訓練命令：
     - 訓練 Chatbot 模型：
       ```bash
       docker compose run --rm fastapi-ai python -c "from app.services.chatbot_service import ChatbotService; ChatbotService()._train_and_save_model(open('/app/data/training_chatbot.csv').read().splitlines(), open('/app/data/training_intent.csv').read().splitlines(), '/app/models_data/trained_chatbot_model.joblib')"
       ```
     - 訓練 Sentiment 模型：
       ```bash
       docker compose run --rm fastapi-ai python -c "from app.services.sentiment_service import SentimentService; SentimentService()._train_and_save_model(open('/app/data/training_sentiment.csv').read().splitlines(), open('/app/data/training_sentiment.csv').read().splitlines(), '/app/models_data/trained_sentiment_model.joblib')"
       ```
   - **最佳實踐**: 確保數據集至少包含 100-1000 條記錄，涵蓋多樣化情境。驗證數據後，檢查模型文件是否生成於 `models_data/` 目錄。
4. **複製知識庫數據 (首次運行)**:
   - 範例知識庫文件已生成在 `fastapi-ai-service/app/data/knowledge_base.json`。
   - 複製指令：`cp fastapi-ai-service/app/data/knowledge_base.json smart-customer-support-system/knowledge_data/knowledge_base.json`
   - 可根據需求編輯 `knowledge_base.json`，添加更多問答對和關鍵詞。
5. 啟動所有服務：`docker-compose up --build -d`
6. 等待服務啟動 (首次啟動可能需要時間)
7. 運行 Laravel 遷移：`docker-compose exec php-fpm php artisan migrate`
8. (可選) 運行數據填充：`docker-compose exec php-fpm php artisan db:seed`
9. 訪問應用程式：
   - Laravel 前端：`http://localhost`
   - FastAPI 文件：`http://localhost:8001/docs`

### 注意事項
- **管理介面**: 本專案目前未提供預設圖形化管理後台介面 (`http://localhost/admin`)。訪問此路徑將返回 404 錯誤，因為系統專注於後端 API 和 AI 服務。若需管理員操作，請參考「管理員操作指引」使用 API，或開發自訂管理後台。
- **前端開發**: 預設前端僅提供基本交互，需自行開發管理員介面。

## 開發管理後台
為提升管理員與客服的操作體驗，可開發圖形化管理後台。以下是建議步驟：
- **技術選擇**: 推薦使用 Vue.js 作為前端框架，結合 Vue Router 和 Vuex/Pinia 管理狀態。
- **基本結構**:
  - 創建 `admin` 目錄作為管理後台根目錄。
  - 設置路由，例如 `/admin/tickets`（工單列表）、`/admin/users`（用戶管理）。
  - 示例文件結構：
    ```
    admin/
    ├── src/
    │   ├── views/
    │   │   ├── TicketList.vue
    │   │   └── UserList.vue
    │   ├── router/
    │   │   └── index.js
    │   ├── store/
    │   │   └── index.js
    │   └── main.js
    ├── public/
    │   └── index.html
    └── package.json
    ```
- **API 集成**:
  - 使用 Axios 或 Fetch 調用 Laravel API（如 `/api/tickets`），並在請求頭中添加 `Authorization: Bearer <token>`。
  - 示例代碼（`TicketList.vue`）：
    ```javascript
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
- **部署**:
  - 將管理後台靜態文件複製到 `laravel-backend/public/admin/`。
  - 更新 Nginx 配置文件，添加 `location /admin/` 代理至 `public/admin/index.html`。
  - 啟動後訪問 `http://localhost/admin`。

## 管理員操作指引
本系統無預設圖形化管理後台，管理員操作需透過 API 進行。以下是基本步驟：

1. **註冊一個管理員用戶**  
   使用 `/api/register` 端點創建管理員帳號：
   - **URL**: `http://localhost/api/register`
   - **方法**: `POST`
   - **Body (JSON)**:
     ```json
     {
         "name": "Admin User",
         "email": "admin@example.com",
         "password": "your_admin_password",
         "password_confirmation": "your_admin_password",
         "role": "admin"
     }
     ```
   - 替換 `your_admin_password` 為自訂密碼。

2. **登入管理員用戶，獲取存取令牌**  
   使用 `/api/login` 端點獲取授權令牌：
   - **URL**: `http://localhost/api/login`
   - **方法**: `POST`
   - **Body (JSON)**:
     ```json
     {
         "email": "admin@example.com",
         "password": "your_admin_password"
     }
     ```
   - 響應中包含 `access_token` (如 `Bearer ey...`)，請保存此令牌。

3. **使用存取令牌訪問管理員專屬 API**  
   將 `access_token` 添加至 `Authorization` 頭部進行管理操作。例如，獲取所有工單：
   - **URL**: `http://localhost/api/tickets`
   - **方法**: `GET`
   - **Header**:
     ```
     Authorization: Bearer YOUR_ADMIN_ACCESS_TOKEN
     ```
   - 將 `YOUR_ADMIN_ACCESS_TOKEN` 替換為步驟 2 獲取的令牌。

## 測試覆蓋
### 運行測試
1. **Laravel 測試**:
   - 進入 Laravel 容器：`docker-compose exec php-fpm bash`
   - 運行 PHPUnit 測試：`vendor/bin/phpunit`
   - 測試覆蓋 `AuthController` 和 `TicketController` 的核心功能。
2. **FastAPI 測試**:
   - 進入 FastAPI 容器：`docker-compose exec fastapi-ai bash`
   - 運行 Pytest 測試：`pytest tests/`

### 測試文件
- Laravel 測試文件位於 `laravel-backend/tests/`，例如：
  - `Feature/AuthTest.php` 測試用戶註冊和登入。
  - `Feature/TicketTest.php` 測試工單創建和更新。

## 未來改進
- 支援多語言情感分析。
- 整合更多 AI 模型（如 BERT）提升意圖識別準確性。
- 添加故障轉移機制以提升高可用性。
- 開發圖形化管理後台（建議使用 Vue.js 或 React.js）。

## 許可證
採用 [MIT 許可證](LICENSE).
