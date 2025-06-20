#!/bin/bash

PROJECT_NAME="smart-customer-support-system"
LARAVEL_DIR="$PROJECT_NAME/laravel-backend"
FASTAPI_DIR="$PROJECT_NAME/fastapi-ai-service"
NGINX_DIR="$PROJECT_NAME/nginx"

echo "==================================================="
echo "  智慧型客服與支援系統專案自動生成腳本 (最終增強版)"
echo "==================================================="
echo "目標專案目錄: $PROJECT_NAME"
echo ""

# 詢問使用者是否確認執行，並提示潛在的覆蓋風險
read -p "這個腳本會建立新的專案目錄並可能覆蓋現有內容。是否繼續？(y/N) " -n 1 -r
echo    # 移動到新的一行
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "操作已取消。"
    exit 1
fi

# 檢查 Docker 和 Docker Compose 是否安裝
if ! command -v docker &> /dev/null
then
    echo "警告: Docker 未安裝。請先安裝 Docker。"
fi

if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null
then
    echo "警告: Docker Compose 未安裝。請先安裝 Docker Compose。"
fi

echo "正在建立專案目錄結構..."

# 刪除舊的專案目錄，如果存在的話
if [ -d "$PROJECT_NAME" ]; then
    echo "偵測到現有專案目錄 '$PROJECT_NAME'，正在刪除..."
    rm -rf "$PROJECT_NAME"
fi

mkdir -p "$LARAVEL_DIR/routes" "$LARAVEL_DIR/app/Http/Controllers" "$LARAVEL_DIR/app/Models" "$LARAVEL_DIR/app/Jobs" "$LARAVEL_DIR/database/migrations" "$LARAVEL_DIR/config"
mkdir -p "$FASTAPI_DIR/app/api" "$FASTAPI_DIR/app/services" "$FASTAPI_DIR/app/models" "$FASTAPI_DIR/app/utils" "$FASTAPI_DIR/tests" "$FASTAPI_DIR/data"
mkdir -p "$NGINX_DIR"

echo "目錄結構建立完成。"

echo "正在生成 README.md..."
cat << EOF > "$PROJECT_NAME/README.md"
# 智能客服與支援系統 (Smart Customer Service and Support System)

## 專案概述
此專案旨在建立一個高度自動化、能顯著提升客服效率的智慧型客服平台。系統結合了 Laravel 框架處理後端管理、票務系統與用戶介面，並透過 FastAPI 整合先進的 AI 技術，實現智能聊天機器人、情感分析、智能工單分派及知識庫推薦等功能。

## 專案目標
- **提升客服效率**：透過自動化回答、智能分派，減少人工介入時間。
- **優化客戶體驗**：提供快速、準確的回覆，並優先處理高情緒問題。
- **數據驅動決策**：提供豐富的儀表板數據，協助管理層優化服務流程。
- **彈性整合能力**：透過 Webhook 接收多渠道訊息，便於擴展。

## 技術棧
- **後端管理 (Laravel)**:
    - 用戶管理 (User Management)
    - 票務系統 (Ticketing System)
    - 儀表板 (Dashboard)
    - Web Hook 接收 (Webhook Receiver) + **非同步 Job 處理**
- **AI 服務 (FastAPI + Python)**:
    - 智能聊天機器人 (Chatbot): 基於 NLP 模型 (scikit-learn 示例，可升級 BERT/GPT)
    - 情感分析 (Sentiment Analysis): 對客戶對話進行情感判斷
    - 智能工單分派 (Intelligent Ticket Dispatch): 自動分類與分派
    - 知識庫推薦 (Knowledge Base Recommendation): 智能檢索 FAQ (從 JSON 文件加載)
    - **模組化服務層**: 清晰分離 API 路由與 AI 模型邏輯
    - **統一錯誤處理**: 自定義異常類和處理器，提供一致的錯誤響應
- **資料庫**: MySQL
- **消息隊列**: Redis (用於 Laravel Queue)
- **容器化**: Docker & Docker Compose
- **監控潛力**: Prometheus + Grafana (概念提及，建議後續集成)

## 專案架構圖
\`\`\`mermaid
graph TD
    User --&gt; Web/App
    Web/App --&gt; Webhook Receiver (Laravel)
    Webhook Receiver (Laravel) --&gt; AI Processing Job (Laravel Queue/Redis)
    AI Processing Job --&gt; Chatbot API (FastAPI)
    Chatbot API (FastAPI) --&gt; AI Service Layer (NLP, Sentiment, etc.)
    AI Service Layer --&gt; Knowledge Base (JSON/DB/Volume)
    AI Service Layer --&gt; Persistent Models (Volume)
    Chatbot API (FastAPI) --&gt; Ticket System (Laravel)
    Ticket System (Laravel) --&gt; Customer Service Agent
    Customer Service Agent --&gt; Dashboard (Laravel)
    Observability(Monitoring: Prometheus, Grafana) &lt;-- FastAPI
\`\`\`

## 功能詳述

### Laravel 後端 (API Driven)
- **用戶管理**: 客服人員與客戶的註冊、登入、權限管理。
- **票務系統**: 客戶建立工單，客服人員查看、回應、更新工單狀態。
- **儀表板**: 實時工單統計、客服人員績效指標、客戶滿意度概覽。
- **Web Hook 接收**: 提供一個安全的 API 端點，接收來自網站、App 等第三方平台的訊息。
    - **安全性考量**: 建議為此端點實施 IP 白名單或請求簽名驗證，以防止未經授權的訪問或濫用。
- **異步處理**: 透過 Laravel Queue (基於 Redis) 將 AI 處理任務轉移到後台執行，提高 Webhook 響應速度並支持重試機制。

### FastAPI + AI 服務
- **智能聊天機器人 (Chatbot)**: 接收用戶自然語言問題，透過 NLP 模型理解意圖，提供自動回覆或引導。
- **情感分析 (Sentiment Analysis)**: 分析客戶輸入文字的情感傾向 (正面、負面、中立)，標記高負面情緒的工單。
- **智能工單分派 (Intelligent Ticket Dispatch)**: 基於工單內容自動判斷問題類別，推薦或自動分派給最適合的客服人員或部門。
- **知識庫推薦 (Knowledge Base Recommendation)**: 分析客戶問題，從預設的 FAQ 或解決方案知識庫中查找最相關的條目，支持從 JSON 文件動態載入。
- **模組化服務層**: AI 模型的核心邏輯封裝在獨立的服務層中，與 FastAPI 路由解耦，便於擴展和維護。
- **統一錯誤處理**: 定義自定義異常並統一處理，提供清晰的錯誤響應格式。
- **模型持久化**: AI 模型和知識庫數據通過 Docker volumes 持久化，避免容器重建時重複訓練/下載。

## 環境設定與運行

### 前提條件
- Docker & Docker Compose
- Git

### 步驟 1: 克隆專案
\`\`\`bash
git clone https://github.com/YourUsername/your-customer-support-system.git
cd your-customer-support-system
\`\`\`

### 步驟 2: 配置環境變數
進入 \`laravel-backend\` 和 \`fastapi-ai-service\` 目錄，複製 \`.env.example\` 為 \`.env\`，並根據你的環境修改配置。

**\`laravel-backend/.env\` (主要關注資料庫配置和 FastAPI URL)**
\`\`\`dotenv
APP_NAME="Laravel Smart CS"
APP_ENV=local
APP_KEY= # 請運行 php artisan key:generate 生成
APP_DEBUG=true
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=your_database_name
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis # 使用 Redis 作為隊列驅動
SESSION_DRIVER=file
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_HOST=
MAIL_PORT=
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="\${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=mt1

VITE_APP_NAME="\${APP_NAME}"
VITE_PUSHER_APP_KEY="\${PUSHER_APP_KEY}"
VITE_PUSHER_APP_CLUSTER="\${PUSHER_APP_CLUSTER}"

# FastAPI AI Service URL (For Laravel to communicate with FastAPI)
FASTAPI_AI_SERVICE_URL=http://fastapi-ai:8001
\`\`\`

**\`fastapi-ai-service/.env\` (如果你的 AI 服務需要外部 API Key 或模型路徑)**
\`\`\`dotenv
# Optional: API keys for external AI services or model paths
# OPENAI_API_KEY=your_openai_key
# HUGGING_FACE_TOKEN=your_huggingface_token
MODEL_DIR=/app/models # 存放 AI 模型文件的目錄 (映射到 Docker volume)

# Knowledge Base JSON file path
KNOWLEDGE_BASE_PATH=/app/data/knowledge_base.json # 知識庫文件路徑 (映射到 Docker volume)
\`\`\`

### 步驟 3: 啟動 Docker 容器
\`\`\`bash
cd your-customer-support-system
docker compose up -d --build
\`\`\`
這將會構建 Docker 映像檔並啟動所有服務。第一次運行時，FastAPI 會訓練並保存 AI 模型和知識庫到 `models_data` 和 `knowledge_data` Docker volumes 中。

### 步驟 4: 進入 Laravel 容器並完成設定
\`\`\`bash
docker compose exec php-fpm bash

# 在容器內部執行 Composer 安裝
composer install

# 生成 Laravel App Key
php artisan key:generate

# 運行資料庫遷移和填充 (可選)
php artisan migrate --seed

# 安裝前端依賴並編譯 (如果你的 Laravel 專案包含前端資源，如 Blade 模板與 Vue/React)
npm install
npm run dev # 或 npm run watch, npm run prod

exit # 退出容器
\`\`\`
**注意**: Laravel Queue Worker 將由 Supervisor 在 \`php-fpm\` 容器內部自動啟動。

### 步驟 5: 訪問應用
- **Laravel 後端**: \`http://localhost\`
- **FastAPI AI 服務**: \`http://localhost:8001/docs\` (查看 API 文檔)

## 運行測試
\`\`\`bash
# Laravel 測試
docker compose exec php-fpm php artisan test

# FastAPI 測試 (運行所有測試)
docker compose exec fastapi-ai pytest
# FastAPI 運行特定測試文件 (例如：僅測試 chatbot 服務)
docker compose exec fastapi-ai pytest tests/test_chatbot_service.py
\`\`\`

## 未來優化與改進

### 1. 錯誤處理與觀測性
- **FastAPI 統一錯誤處理**: 已有自定義異常類 \`APIException\` 和相應的異常處理器，確保所有錯誤響應格式一致。
- **OpenTelemetry 集成**: 引入 OpenTelemetry + Prometheus + Grafana 進行端到端監控。
    - 在 FastAPI 中集成 OpenTelemetry SDK 和儀表化庫 (\`opentelemetry-instrumentation-fastapi\`)，啟用請求追蹤、指標收集和日誌關聯。
    - 暴露 Prometheus 指標 (e.g., \`/metrics\`)，監控各模型推理延遲、錯誤率、資源利用率。
    - 使用 Grafana 搭建儀表板，可視化這些指標和追蹤數據，便於問題診斷和性能瓶頸分析。
- **日誌聚合**: 部署 ELK Stack (Elasticsearch, Logstash, Kibana) 或 Grafana Loki 來集中管理 Laravel 和 FastAPI 的日誌。

### 2. 資料與模型彈性
- **知識庫動態編輯與版本化**:
    - 將知識庫數據從 JSON 文件遷移到資料庫中 (如 MySQL, PostgreSQL)。
    - 開發後台 CMS 或管理界面，允許非技術人員動態編輯、新增、刪除知識庫條目。
    - 實施知識庫的版本控制和 A/B 測試機制，確保內容更新的穩定性。
    - 考慮更高級的檢索增強生成 (RAG) 模式，結合向量數據庫 (e.g., Pinecone, Weaviate) 提升搜尋精度。
- **AI 模型管理與再訓練**:
    - 引入模型版本控制 (e.g., DVC, MLflow Models) 和模型註冊中心。
    - 建立自動化模型再訓練管道 (CI/CD for ML)，根據新數據或性能指標觸發模型更新。
    - 考慮模型量化或蒸餾等技術，以優化推理速度和資源消耗。

### 3. 可擴展性與併發處理
- **Laravel 身份驗證增強**:
    - 如果考慮前後端完全分離或導入移動客戶端，建議整合 Laravel Passport (OAuth2 provider) 或針對 JWT 的 Sanctum 配置，提供更安全的 API 驗證機制。
- **Docker 網路與負載均衡**:
    - 考慮採用 Traefik 或 NGINX + Let's Encrypt + Auto TLS 作為反向代理和負載均衡器，以支援多環境部署、自動 TLS 證書管理和更靈活的路由配置。
    - 在生產環境中，考慮使用 Kubernetes 或 Docker Swarm 進行容器編排，實現自動擴縮容、高可用性和更複雜的部署策略。

### 4. 測試與 CI/CD
- **全面的單元測試**:
    - **FastAPI**: 為所有 AI 服務模組 (chatbot, sentiment, dispatch, knowledge_base) 編寫全面的單元測試，涵蓋正常邏輯、邊緣案例、錯誤處理和性能指標。
    - **Laravel**: 擴展 Laravel 側的測試，特別是針對 `WebhookController` 接收、Job 分派、以及 `TicketController` 的授權、輸入驗證、業務邏輯等。使用 Laravel 的測試工具 (\`php artisan test\`)。
- **CI/CD 持續整合/交付**:
    - 設定 GitHub Actions 或 GitLab CI/CD 管道，自動化執行：
        - 代碼風格檢查 (e.g., Pint for PHP, Black/Ruff for Python)
        - 靜態代碼分析 (e.g., PHPStan, MyPy)
        - 單元測試與集成測試
        - 構建 Docker 映像檔
        - 部署到測試/生產環境 (CD)

## 貢獻指南
(如果你希望他人貢獻，可以添加此部分)

## 授權
MIT License

## 聯繫方式
你的名字 - 你的 Email - [你的 LinkedIn 連結] - [你的個人網站/作品集連結]
EOF
echo "README.md 生成完成。"

echo "正在生成 Laravel 骨架..."

# laravel-backend/.env.example
cat << EOF > "$LARAVEL_DIR/.env.example"
APP_NAME="Laravel Smart CS"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=your_database_name # <<< 請修改
DB_USERNAME=your_db_user      # <<< 請修改
DB_PASSWORD=your_db_password  # <<< 請修改

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis # <<< 更改為 Redis
SESSION_DRIVER=file
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_HOST=
MAIL_PORT=
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="\${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=mt1

VITE_APP_NAME="\${APP_NAME}"
VITE_PUSHER_APP_KEY="\${PUSHER_APP_KEY}"
VITE_PUSHER_APP_CLUSTER="\${PUSHER_APP_CLUSTER}"

FASTAPI_AI_SERVICE_URL=http://fastapi-ai:8001
EOF

# laravel-backend/composer.json (基本 Laravel 框架的 composer.json 內容)
cat << 'EOF' > "$LARAVEL_DIR/composer.json"
{
    "name": "laravel/laravel",
    "type": "project",
    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "Database\\Factories\\": "database/factories/",
            "Database\\Seeders\\": "database/seeders/"
        }
    },
    "require": {
        "php": "^8.2",
        "guzzlehttp/guzzle": "^7.8",
        "laravel/framework": "^11.0",
        "laravel/sanctum": "^4.0",
        "laravel/tinker": "^2.9",
        "predis/predis": "^2.0"
    },
    "require-dev": {
        "fakerphp/faker": "^1.23",
        "laravel/pint": "^1.13",
        "laravel/sail": "^1.26",
        "mockery/mockery": "^1.6",
        "nunomaduro/collision": "^8.1",
        "phpunit/phpunit": "^11.0.1",
        "spatie/laravel-ignition": "^2.4"
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true,
        "allow-plugins": {
            "pestphp/pest-plugin": true,
            "php-http/discovery": true
        }
    },
    "minimum-stability": "stable",
    "prefer-stable": true,
    "scripts": {
        "post-autoload-dump": [
            "Illuminate\\Foundation\\ComposerScripts::postAutoloadDump",
            "@php artisan package:discover --ansi"
        ],
        "post-update-cmd": [
            "@php artisan vendor:publish --tag=laravel-assets --ansi --force"
        ],
        "post-root-package-install": [
            "@php -r \"file_exists('.env') || copy('.env.example', '.env');\""
        ],
        "post-create-project-cmd": [
            "@php artisan key:generate --ansi"
        ]
    }
}
EOF

# laravel-backend/routes/api.php
cat << 'EOF' > "$LARAVEL_DIR/routes/api.php"
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\WebhookController;
use App\Http\Controllers\TicketController;
use App\Http\Controllers\UserController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Webhook 接收，處理來自外部系統的訊息
// !! 安全性提醒: 考慮為此端點增加 IP 白名單、請求簽名驗證或 API Key 等安全措施。
Route::post('/webhook/incoming', [WebhookController::class, 'handleIncomingMessage']);

// 用戶認證
Route::post('/register', [UserController::class, 'register']);
Route::post('/login', [UserController::class, 'login']);

// 需要認證的路由 (使用 Laravel Sanctum 示例)
Route::middleware('auth:sanctum')->group(function () {
    // 用戶管理
    Route::apiResource('users', UserController::class);

    // 票務系統
    Route::apiResource('tickets', TicketController::class);
    Route::post('/tickets/{ticket}/reply', [TicketController::class, 'addReply']);

    // 儀表板數據
    Route::get('/dashboard/stats', [TicketController::class, 'getDashboardStats']);

    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});
EOF

# laravel-backend/app/Http/Controllers/WebhookController.php
cat << 'EOF' > "$LARAVEL_DIR/app/Http/Controllers/WebhookController.php"
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Jobs\ProcessIncomingWebhook; // 導入新創建的 Job

class WebhookController extends Controller
{
    /**
     * 處理來自第三方平台的進站訊息。
     * 將 AI 處理邏輯轉交給 Job 異步執行。
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function handleIncomingMessage(Request $request)
    {
        Log::info('Received webhook incoming message (Controller):', $request->all());

        // !! 安全性提醒: 在生產環境中，應在此處加入額外的安全性檢查，
        // 例如驗證請求來源的 IP 白名單，或驗證請求頭中的簽名/API Key。
        // if (!$this->isValidSignature($request)) {
        //     Log::warning('WebhookController: Invalid signature for incoming webhook.', $request->all());
        //     return response()->json(['message' => 'Unauthorized'], 403);
        // }

        $messageContent = $request->input('message');
        $customerIdentifier = $request->input('customer_id') ?? $request->input('sender_id');
        $source = $request->input('source', 'unknown');

        if (!$messageContent || !$customerIdentifier) {
            Log::warning('WebhookController: Missing required parameters.', $request->all());
            return response()->json(['message' => 'Missing required parameters'], 400);
        }

        try {
            // 將 AI 處理邏輯推送到隊列
            // 使用 dispatch() 確保 Job 會被推送到隊列中，異步執行
            ProcessIncomingWebhook::dispatch($messageContent, $customerIdentifier, $source);

            Log::info('WebhookController: Message dispatched to queue for processing.');

            return response()->json([
                'status' => 'accepted',
                'message' => 'Message received and queued for AI processing.',
                'customer_id' => $customerIdentifier,
                'source' => $source
            ], 202); // 返回 202 Accepted 表示請求已被接受，但處理尚未完成

        } catch (\Exception $e) {
            Log::error('WebhookController: Error dispatching job: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json(['message' => 'Error queuing message for processing', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * 示例：驗證請求簽名 (需要根據實際集成平台實現)
     * @param Request $request
     * @return bool
     */
    // protected function isValidSignature(Request $request): bool
    // {
    //     $secret = env('WEBHOOK_SECRET_KEY'); // 從 .env 獲取你的 Webhook Secret
    //     $signature = $request->header('X-Webhook-Signature'); // 假設簽名在 header 中

    //     if (!$secret || !$signature) {
    //         return false;
    //     }

    //     // 這裡實現你的簽名驗證邏輯，例如 HMAC SHA256
    //     // $payload = $request->getContent();
    //     // $expectedSignature = hash_hmac('sha256', $payload, $secret);
    //     // return hash_equals($expectedSignature, $signature);

    //     return true; // 僅為示例，實際請實現驗證邏輯
    // }
}
EOF

# laravel-backend/app/Jobs/ProcessIncomingWebhook.php
cat << 'EOF' > "$LARAVEL_DIR/app/Jobs/ProcessIncomingWebhook.php"
<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use App\Models\Ticket;
use App\Models\User; // 如果需要根據 AI 推薦的 ID 找到客服

class ProcessIncomingWebhook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $messageContent;
    protected $customerIdentifier;
    protected $source;

    /**
     * The number of times the job may be attempted.
     *
     * @var int
     */
    public $tries = 3; // 嘗試 3 次

    /**
     * The number of seconds to wait before retrying the job.
     *
     * @var int
     */
    public $backoff = 5; // 每次重試間隔 5 秒

    /**
     * Create a new job instance.
     *
     * @param string $messageContent
     * @param string $customerIdentifier
     * @param string $source
     * @return void
     */
    public function __construct(string $messageContent, string $customerIdentifier, string $source)
    {
        $this->messageContent = $messageContent;
        $this->customerIdentifier = $customerIdentifier;
        $this->source = $source;
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        Log::info('ProcessIncomingWebhook Job: Starting processing for customer ' . $this->customerIdentifier);

        try {
            $fastApiUrl = env('FASTAPI_AI_SERVICE_URL', 'http://fastapi-ai:8001'); // 從 .env 讀取

            // 向 FastAPI AI 服務發送請求
            $aiResponse = Http::timeout(30)->post("{$fastApiUrl}/ai/process_message", [
                'message' => $this->messageContent,
                'customer_id' => $this->customerIdentifier,
                'source' => $this->source
            ])->json();

            Log::info('ProcessIncomingWebhook Job: FastAPI AI response:', $aiResponse);

            // 根據 AI 的響應來決定下一步操作
            $intent = $aiResponse['intent'] ?? 'unresolved';
            $sentiment = $aiResponse['sentiment'] ?? 'neutral';
            $suggestedReply = $aiResponse['suggested_reply'] ?? null;
            $recommendedAgentId = $aiResponse['recommended_agent_id'] ?? null;
            $ticketCategory = $aiResponse['ticket_category'] ?? 'General';
            $knowledgeBaseMatches = $aiResponse['knowledge_base_match'] ?? [];

            // 創建或更新工單
            $ticket = Ticket::firstOrCreate(
                ['customer_identifier' => $this->customerIdentifier, 'status' => 'pending'], // 示例：查找客戶待處理的工單
                [
                    'subject' => '自動化工單 - ' . $intent,
                    'description' => $this->messageContent,
                    'status' => 'pending',
                    'priority' => ($sentiment === 'negative' ? 'high' : 'medium'),
                    'assigned_to_user_id' => $recommendedAgentId,
                    'category' => $ticketCategory
                ]
            );

            // TODO: 如果有建議回覆，可以實現自動回覆客戶的邏輯
            if ($suggestedReply) {
                // $ticket->replies()->create(['user_id' => null, 'content' => $suggestedReply]); // 假設 AI 回覆者為 null
                Log::info("ProcessIncomingWebhook Job: Suggested reply for customer {$this->customerIdentifier}: {$suggestedReply}");
            }

            Log::info('ProcessIncomingWebhook Job: Ticket ' . $ticket->id . ' created/updated.');

        } catch (\Illuminate\Http\Client\RequestException $e) {
            $statusCode = $e->response ? $e->response->status() : 500;
            $errorMessage = $e->response ? $e->response->body() : $e->getMessage();
            Log::error('ProcessIncomingWebhook Job: HTTP Error communicating with FastAPI AI service: ' . $errorMessage, ['status' => $statusCode, 'trace' => $e->getTraceAsString()]);
            // 如果是可重試的 HTTP 錯誤 (e.g., 5xx, 429), 可以選擇重新發布 Job
            if ($statusCode >= 500 || $statusCode == 429) {
                $this->release(10); // 10 秒後重試
            } else {
                $this->fail($e); // 對於其他錯誤，直接標記為失敗
            }
        } catch (\Exception $e) {
            Log::error('ProcessIncomingWebhook Job: Error processing: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            // 對於其他類型的錯誤，可以選擇重試或將 Job 標記為失敗
            $this->fail($e); // 將 Job 標記為失敗，將其移至 failed_jobs 表
        }
    }

    /**
     * Handle a job that was failed.
     *
     * @param  \Throwable  $exception
     * @return void
     */
    public function failed(\Throwable $exception)
    {
        Log::error('ProcessIncomingWebhook Job: Failed for customer ' . $this->customerIdentifier . ': ' . $exception->getMessage());
        // 可以發送通知給管理員，或記錄到其他監控系統
    }
}
EOF

# laravel-backend/app/Http/Controllers/TicketController.php (與之前相同，因為 Job 處理 AI 邏輯)
# 確保這些文件已存在，這裡只是佔位符，實際應有完整的 Laravel 控制器內容
cat << 'EOF' > "$LARAVEL_DIR/app/Http/Controllers/TicketController.php"
<?php

namespace App\Http\Controllers;

use App\Models\Ticket;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use App\Models\TicketReply; // 引入 TicketReply 模型

class TicketController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        // 只有管理員或客服才能查看所有工單
        if (Auth::user()->is_admin || Auth::user()->is_support_agent) {
            $tickets = Ticket::with('assignedToUser')->latest()->paginate(10);
        } else {
            // 普通用戶只能查看自己的工單
            $tickets = Ticket::where('customer_identifier', Auth::user()->email) // 假設 customer_identifier 是用戶email
                             ->with('assignedToUser')
                             ->latest()
                             ->paginate(10);
        }
        return response()->json($tickets);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'subject' => 'required|string|max:255',
            'description' => 'required|string',
            // 'customer_identifier' => 'required|string|email|max:255', // 如果是API創建，客戶識別符可以從認證用戶獲取
            'priority' => ['sometimes', 'required', Rule::in(['low', 'medium', 'high'])],
            'category' => 'sometimes|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $ticket = new Ticket($request->all());
        // 假設 authenticated user's email is the customer_identifier
        $ticket->customer_identifier = Auth::user()->email;
        $ticket->status = 'pending'; // 默認狀態
        $ticket->save();

        return response()->json($ticket, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Ticket $ticket)
    {
        // 授權檢查：只有管理員、被指派的客服或工單的發起者才能查看
        if (Auth::user()->is_admin || 
            Auth::user()->is_support_agent && $ticket->assigned_to_user_id === Auth::id() ||
            $ticket->customer_identifier === Auth::user()->email) {
            
            return response()->json($ticket->load(['assignedToUser', 'replies.user']));
        }

        return response()->json(['message' => 'Unauthorized'], 403);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Ticket $ticket)
    {
        // 授權檢查：只有管理員或被指派的客服才能更新
        if (!Auth::user()->is_admin && !(Auth::user()->is_support_agent && $ticket->assigned_to_user_id === Auth::id())) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'subject' => 'sometimes|string|max:255',
            'description' => 'sometimes|string',
            'status' => ['sometimes', Rule::in(['pending', 'in_progress', 'resolved', 'closed'])],
            'priority' => ['sometimes', Rule::in(['low', 'medium', 'high'])],
            'assigned_to_user_id' => 'sometimes|nullable|exists:users,id',
            'category' => 'sometimes|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $ticket->update($request->all());

        return response()->json($ticket);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Ticket $ticket)
    {
        // 授權檢查：只有管理員才能刪除
        if (!Auth::user()->is_admin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $ticket->delete();

        return response()->json(['message' => 'Ticket deleted successfully']);
    }

    /**
     * Add a reply to a ticket.
     */
    public function addReply(Request $request, Ticket $ticket)
    {
        // 授權檢查：只有管理員、被指派的客服或工單的發起者才能回覆
        if (!Auth::user()->is_admin && 
            !(Auth::user()->is_support_agent && $ticket->assigned_to_user_id === Auth::id()) &&
            $ticket->customer_identifier !== Auth::user()->email) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'content' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $reply = new TicketReply([
            'content' => $request->input('content'),
            'user_id' => Auth::id(), // 回覆者是當前認證用戶
        ]);

        $ticket->replies()->save($reply);

        // 如果工單狀態是 resolved 或 closed，有新回覆時可以考慮改回 in_progress
        if (in_array($ticket->status, ['resolved', 'closed'])) {
            $ticket->status = 'in_progress';
            $ticket->save();
        }

        return response()->json($reply->load('user'), 201);
    }

    /**
     * Get dashboard statistics.
     */
    public function getDashboardStats()
    {
        // 只有管理員可以查看儀表板數據
        if (!Auth::user()->is_admin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $totalTickets = Ticket::count();
        $pendingTickets = Ticket::where('status', 'pending')->count();
        $inProgressTickets = Ticket::where('status', 'in_progress')->count();
        $resolvedTickets = Ticket::where('status', 'resolved')->count();
        $closedTickets = Ticket::where('status', 'closed')->count();
        $highPriorityTickets = Ticket::where('priority', 'high')->count();

        // 可以在這裡添加更複雜的統計，例如每個客服處理的工單數，平均響應時間等
        $agentStats = Ticket::selectRaw('assigned_to_user_id, count(*) as total_assigned_tickets')
                            ->groupBy('assigned_to_user_id')
                            ->with('assignedToUser')
                            ->get();

        return response()->json([
            'total_tickets' => $totalTickets,
            'pending_tickets' => $pendingTickets,
            'in_progress_tickets' => $inProgressTickets,
            'resolved_tickets' => $resolvedTickets,
            'closed_tickets' => $closedTickets,
            'high_priority_tickets' => $highPriorityTickets,
            'agent_statistics' => $agentStats,
        ]);
    }
}
EOF

# laravel-backend/app/Http/Controllers/UserController.php (與之前相同)
cat << 'EOF' > "$LARAVEL_DIR/app/Http/Controllers/UserController.php"
<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class UserController extends Controller
{
    /**
     * 用戶註冊。
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'is_admin' => 'sometimes|boolean', // 只有在內部創建管理員時才允許
            'is_support_agent' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'is_admin' => $request->is_admin ?? false,
            'is_support_agent' => $request->is_support_agent ?? false,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json(['message' => 'User registered successfully', 'access_token' => $token, 'token_type' => 'Bearer'], 201);
    }

    /**
     * 用戶登入。
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['message' => 'Invalid login details'], 401);
        }

        $user = User::where('email', $request->email)->firstOrFail();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json(['message' => 'Logged in successfully', 'access_token' => $token, 'token_type' => 'Bearer', 'user' => $user]);
    }

    /**
     * 登出
     */
    public function logout(Request $request)
    {
        Auth::user()->tokens()->delete();
        return response()->json(['message' => 'Logged out successfully']);
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        // 只有管理員能查看所有用戶
        if (!Auth::user()->is_admin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        $users = User::all();
        return response()->json($users);
    }

    /**
     * Display the specified resource.
     */
    public function show(User $user)
    {
        // 只有管理員或用戶自己能查看
        if (!Auth::user()->is_admin && Auth::id() !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        return response()->json($user);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, User $user)
    {
        // 只有管理員或用戶自己能更新自己的部分資料
        if (!Auth::user()->is_admin && Auth::id() !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,' . $user->id,
            'password' => 'sometimes|string|min:8|confirmed',
            'is_admin' => 'sometimes|boolean',
            'is_support_agent' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // 非管理員用戶不能修改 is_admin 或 is_support_agent 狀態
        if (!Auth::user()->is_admin) {
            $request->offsetUnset('is_admin');
            $request->offsetUnset('is_support_agent');
        }

        $user->name = $request->name ?? $user->name;
        $user->email = $request->email ?? $user->email;
        if ($request->has('password')) {
            $user->password = Hash::make($request->password);
        }
        $user->is_admin = $request->is_admin ?? $user->is_admin;
        $user->is_support_agent = $request->is_support_agent ?? $user->is_support_agent;
        $user->save();

        return response()->json($user);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(User $user)
    {
        // 只有管理員能刪除用戶
        if (!Auth::user()->is_admin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        $user->delete();
        return response()->json(['message' => 'User deleted successfully']);
    }
}
EOF

# laravel-backend/app/Models/User.php (與之前相同)
cat << 'EOF' > "$LARAVEL_DIR/app/Models/User.php"
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'is_admin',
        'is_support_agent',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'is_admin' => 'boolean', // 確保這是 boolean 類型
        'is_support_agent' => 'boolean', // 確保這是 boolean 類型
    ];

    // User 可以有多個 Tickets
    public function tickets()
    {
        return $this->hasMany(Ticket::class, 'assigned_to_user_id');
    }

    // User 可以有多個 TicketReplies (作為回覆者)
    public function replies()
    {
        return $this->hasMany(TicketReply::class, 'user_id');
    }
}
EOF

# laravel-backend/app/Models/Ticket.php (與之前相同)
cat << 'EOF' > "$LARAVEL_DIR/app/Models/Ticket.php"
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ticket extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_identifier',
        'subject',
        'description',
        'status',
        'priority',
        'assigned_to_user_id',
        'category',
    ];

    // 工單可以被指派給一個用戶 (客服)
    public function assignedToUser()
    {
        return $this->belongsTo(User::class, 'assigned_to_user_id');
    }

    // 工單可以有多個回覆
    public function replies()
    {
        return $this->hasMany(TicketReply::class);
    }
}
EOF

# laravel-backend/app/Models/TicketReply.php (與之前相同)
cat << 'EOF' > "$LARAVEL_DIR/app/Models/TicketReply.php"
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TicketReply extends Model
{
    use HasFactory;

    protected $fillable = [
        'ticket_id',
        'user_id',
        'content',
    ];

    // 回覆屬於哪個工單
    public function ticket()
    {
        return $this->belongsTo(Ticket::class);
    }

    // 回覆是由哪個用戶發出的 (客服或客戶)
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
EOF

# Laravel Database Migrations (提供示例檔案，需要手動複製到實際生成的 Migration 文件中)
cat << 'EOF' > "$LARAVEL_DIR/database/migrations/YYYY_MM_DD_HHMMSS_create_users_table.php.example"
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->boolean('is_admin')->default(false); // 是否為管理員
            $table->boolean('is_support_agent')->default(false); // 是否為客服人員
            $table->rememberToken();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
EOF

cat << 'EOF' > "$LARAVEL_DIR/database/migrations/YYYY_MM_DD_HHMMSS_create_tickets_table.php.example"
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tickets', function (Blueprint $table) {
            $table->id();
            $table->string('customer_identifier'); // 用戶的email或其他識別碼
            $table->string('subject');
            $table->text('description');
            $table->enum('status', ['pending', 'in_progress', 'resolved', 'closed'])->default('pending');
            $table->enum('priority', ['low', 'medium', 'high'])->default('medium');
            $table->foreignId('assigned_to_user_id')->nullable()->constrained('users')->onDelete('set null'); // 指派給哪個客服
            $table->string('category')->nullable(); // 工單類別，例如：技術、帳務、售後
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tickets');
    }
};
EOF

cat << 'EOF' > "$LARAVEL_DIR/database/migrations/YYYY_MM_DD_HHMMSS_create_ticket_replies_table.php.example"
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('ticket_replies', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ticket_id')->constrained('tickets')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade'); // 回覆者，可以是客服或客戶
            $table->text('content');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ticket_replies');
    }
};
EOF

# Supervisor 配置 (用於運行 Queue Worker)
mkdir -p "$LARAVEL_DIR/docker-config"
cat << 'EOF' > "$LARAVEL_DIR/docker-config/supervisord.conf"
[supervisord]
nodaemon=true

[program:php-fpm]
command=php-fpm
autostart=true
autorestart=true
priority=5
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:laravel-queue-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work --verbose --tries=3 --timeout=90
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=1 # 可以根據需求增加 worker 進程數
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

# Laravel Dockerfile (新增 supervisor 安裝與執行)
cat << 'EOF' > "$LARAVEL_DIR/Dockerfile"
FROM php:8.2-fpm

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nodejs \
    npm \
    libzip-dev \
    libicu-dev \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 安裝 PHP 擴展
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd opcache zip intl

# 安裝 Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html

# 複製 Composer 相關文件和 .env.example 以便在容器內安裝依賴
COPY composer.json composer.lock ./
COPY .env.example ./

# 安裝 Composer 依賴
RUN composer install --no-dev --optimize-autoloader

# 複製 Node.js 相關文件
COPY package.json package-lock.json ./

# 安裝 Node.js 依賴並編譯前端資源 (如果你的 Laravel 專案包含前端)
# 這步會下載大量 Node 模組，如果前端由獨立容器或 CI/CD 處理，此處可省略。
RUN npm install && npm run prod

# 複製所有 Laravel 應用文件
COPY . .

# 設定權限
RUN chown -R www-data:www-data storage bootstrap/cache
RUN chmod -R 775 storage bootstrap/cache

# 複製 Supervisor 配置
COPY docker-config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 9000
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
EOF

echo "Laravel 骨架生成完成。"

echo "正在生成 FastAPI + AI 服務骨架..."

# fastapi-ai-service/requirements.txt
cat << EOF > "$FASTAPI_DIR/requirements.txt"
fastapi
uvicorn
python-multipart # 如果你需要接收文件
scikit-learn # 基礎機器學習
nltk # 自然語言處理工具
pandas # 數據處理
numpy # 數值計算
python-dotenv # 用於載入 .env 檔案
joblib # 用於保存/載入 scikit-learn 模型
# prometheus_client # 用於 Prometheus 監控
# opentelemetry-api
# opentelemetry-sdk
# opentelemetry-instrumentation-fastapi # 如果要加 OpenTelemetry
EOF

# fastapi-ai-service/.env.example
cat << EOF > "$FASTAPI_DIR/.env.example"
# Optional: API keys for external AI services or model paths
# OPENAI_API_KEY=your_openai_key
# HUGGING_FACE_TOKEN=your_huggingface_token
MODEL_DIR=/app/models # 存放 AI 模型文件的目錄 (映射到 Docker volume)

# Knowledge Base JSON file path
KNOWLEDGE_BASE_PATH=/app/data/knowledge_base.json # 知識庫文件路徑 (映射到 Docker volume)
EOF

# fastapi-ai-service/app/main.py
cat << 'EOF' > "$FASTAPI_DIR/app/main.py"
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
EOF

# fastapi-ai-service/app/services/exceptions.py
cat << 'EOF' > "$FASTAPI_DIR/app/services/exceptions.py"
from fastapi import HTTPException

class APIException(HTTPException):
    """Base custom exception for API errors."""
    def __init__(self, status_code: int, message: str, code: str = "API_ERROR"):
        super().__init__(status_code=status_code, detail=message)
        self.message = message
        self.code = code

class ModelLoadingError(APIException):
    def __init__(self, model_name: str = "AI Model", detail: str = "Failed to load model."):
        super().__init__(status_code=500, message=f"{model_name} loading error: {detail}", code="MODEL_LOAD_ERROR")

class PredictionError(APIException):
    def __init__(self, model_name: str = "AI Model", detail: str = "Failed to make prediction."):
        super().__init__(status_code=500, message=f"{model_name} prediction error: {detail}", code="PREDICTION_ERROR")

class InvalidInputError(APIException):
    def __init__(self, detail: str = "Invalid input provided."):
        super().__init__(status_code=400, message=f"Invalid input: {detail}", code="INVALID_INPUT")

class ResourceNotFoundError(APIException):
    def __init__(self, resource_name: str = "Resource", detail: str = "Not found."):
        super().__init__(status_code=404, message=f"{resource_name} not found: {detail}", code="RESOURCE_NOT_FOUND")
EOF

# fastapi-ai-service/app/services/chatbot_service.py
cat << 'EOF' > "$FASTAPI_DIR/app/services/chatbot_service.py"
import logging
from typing import Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
import joblib
import os
from app.services.exceptions import ModelLoadingError, PredictionError

logger = logging.getLogger(__name__)

# 模擬訓練數據
TRAINING_DATA = [
    ("我想重置我的密碼", "password_reset"),
    ("忘記登入帳號了怎麼辦", "password_reset"),
    ("訂單什麼時候會送到？", "order_status"),
    ("查一下我的訂單號碼", "order_status"),
    ("可以幫我轉接到人工客服嗎？", "transfer_to_agent"),
    ("你們有客服電話嗎？", "transfer_to_agent"),
    ("謝謝你的幫助", "greeting_thanks"),
    ("這個產品怎麼使用？", "general_inquiry"),
    ("我需要退款", "refund_request"),
    ("請問可以退貨嗎", "refund_request"),
    ("我的帳單有問題", "billing_issue"),
    ("付款失敗", "billing_issue"),
    ("我想了解產品功能", "product_info"),
    ("如何啟用新功能", "product_info"),
    ("帳戶被鎖定了", "account_lock"),
    ("無法登入", "account_lock"),
]

class ChatbotService:
    _instance = None
    _is_initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ChatbotService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._is_initialized:
            self.model_dir = os.getenv("MODEL_DIR", "/app/models") # 使用環境變數或預設值
            self.vectorizer_path = os.path.join(self.model_dir, "chatbot_vectorizer.pkl")
            self.model_path = os.path.join(self.model_dir, "chatbot_model.pkl")
            self.intents = sorted(list(set([label for _, label in TRAINING_DATA]))) # 確保意圖列表順序一致
            self.vectorizer = None
            self.model = None
            self._load_or_train_model()
            self._is_initialized = True

    def _load_or_train_model(self):
        os.makedirs(self.model_dir, exist_ok=True) # 確保模型目錄存在
        if os.path.exists(self.vectorizer_path) and os.path.exists(self.model_path):
            try:
                self.vectorizer = joblib.load(self.vectorizer_path)
                self.model = joblib.load(self.model_path)
                # 簡單驗證加載的模型是否有效
                if not hasattr(self.vectorizer, 'transform') or not hasattr(self.model, 'predict'):
                     raise ValueError("Loaded model or vectorizer is not valid.")
                logger.info("Chatbot model loaded from disk.")
            except Exception as e:
                logger.warning(f"Failed to load chatbot model (may be corrupted or outdated): {e}. Training new one.")
                self._train_and_save_model()
        else:
            logger.info("Chatbot model not found on disk. Training new one.")
            self._train_and_save_model()

    def _train_and_save_model(self):
        try:
            texts = [data[0] for data in TRAINING_DATA]
            labels = [data[1] for data in TRAINING_DATA]

            self.vectorizer = TfidfVectorizer()
            X = self.vectorizer.fit_transform(texts)
            # 確保標籤到數字索引的映射在訓練和預測時一致
            y = [self.intents.index(label) for label in labels] 

            self.model = LogisticRegression(max_iter=1000, random_state=42) # 加入 random_state 以確保可重複性
            self.model.fit(X, y)

            joblib.dump(self.vectorizer, self.vectorizer_path)
            joblib.dump(self.model, self.model_path)
            logger.info("Chatbot model trained and saved successfully.")
        except Exception as e:
            raise ModelLoadingError(model_name="Chatbot", detail=f"Training failed: {e}")

    def predict_intent(self, text: str) -> Tuple[str, float]:
        if not self.model or not self.vectorizer:
            raise ModelLoadingError(model_name="Chatbot", detail="Model not initialized.")
        if not text.strip():
            raise PredictionError(model_name="Chatbot", detail="Input text for prediction cannot be empty.")
            
        try:
            text_vectorized = self.vectorizer.transform([text])
            probabilities = self.model.predict_proba(text_vectorized)[0]
            predicted_intent_idx = self.model.predict(text_vectorized)[0]
            
            intent = self.intents[predicted_intent_idx]
            confidence = probabilities[predicted_intent_idx]
            
            logger.debug(f"Predicted intent for '{text}': {intent} (Confidence: {confidence:.2f})")
            return intent, float(confidence)
        except Exception as e:
            raise PredictionError(model_name="Chatbot", detail=f"Prediction failed: {e}")

    def get_reply(self, intent: str) -> str:
        replies = {
            "password_reset": "關於密碼重置，您可以訪問我們的幫助中心查看指南，或者我為您轉接人工客服。",
            "order_status": "請問您的訂單號碼是多少？請提供後續查詢。",
            "transfer_to_agent": "好的，我將為您轉接人工客服，請稍候。",
            "greeting_thanks": "不客氣，很高興能為您服務！",
            "refund_request": "請提供您的訂單號和退款原因，我們將為您處理退款事宜。",
            "billing_issue": "請問您遇到了什麼樣的帳單問題？可以詳細說明一下嗎？",
            "product_info": "您對哪款產品感興趣？我可以提供更多資訊。",
            "account_lock": "您的帳戶被鎖定了嗎？請說明詳細情況，我可以嘗試幫助您解鎖或轉接。",
            "general_inquiry": "很抱歉，我目前無法理解您的問題。您能詳細描述一下嗎？或者我可以幫您轉接人工客服。",
        }
        return replies.get(intent, replies["general_inquiry"])

# 實例化服務 (單例模式)
chatbot_service = ChatbotService()
EOF

# fastapi-ai-service/app/api/chatbot_api.py (路由層)
cat << 'EOF' > "$FASTAPI_DIR/app/api/chatbot_api.py"
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
EOF

# fastapi-ai-service/app/services/sentiment_service.py
cat << 'EOF' > "$FASTAPI_DIR/app/services/sentiment_service.py"
import logging
from typing import Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.pipeline import Pipeline
import joblib
import os
from app.services.exceptions import ModelLoadingError, PredictionError

logger = logging.getLogger(__name__)

# 模擬情感訓練數據 (簡化)
# 實際中會需要更大、更平衡的數據集
SENTIMENT_TRAINING_DATA = [
    ("我非常滿意你們的服務，感謝！", "positive"),
    ("問題解決得很快，很棒！", "positive"),
    ("沒有任何問題，一切都很好", "positive"),
    ("你們的服務真是太棒了，我會推薦給朋友！", "positive"),
    ("糟糕透了，我非常不滿意", "negative"),
    ("這是一個很差的體驗，無法接受", "negative"),
    ("客服回應太慢了，我很生氣", "negative"),
    ("我的問題沒有得到解決，我很失望", "negative"),
    ("我不確定這個功能怎麼用", "neutral"),
    ("我只是想問一個問題", "neutral"),
    ("收到你們的訊息了", "neutral"),
    ("這項功能似乎需要改進", "neutral"),
]

class SentimentService:
    _instance = None
    _is_initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(SentimentService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._is_initialized:
            self.model_dir = os.getenv("MODEL_DIR", "/app/models")
            self.model_path = os.path.join(self.model_dir, "sentiment_pipeline.pkl")
            self.sentiment_labels = sorted(list(set([label for _, label in SENTIMENT_TRAINING_DATA])))
            self.pipeline = None
            self._load_or_train_model()
            self._is_initialized = True

    def _load_or_train_model(self):
        os.makedirs(self.model_dir, exist_ok=True)
        if os.path.exists(self.model_path):
            try:
                self.pipeline = joblib.load(self.model_path)
                if not hasattr(self.pipeline, 'predict'):
                    raise ValueError("Loaded sentiment pipeline is not valid.")
                logger.info("Sentiment model loaded from disk.")
            except Exception as e:
                logger.warning(f"Failed to load sentiment model (may be corrupted or outdated): {e}. Training new one.")
                self._train_and_save_model()
        else:
            logger.info("Sentiment model not found on disk. Training new one.")
            self._train_and_save_model()

    def _train_and_save_model(self):
        try:
            texts = [data[0] for data in SENTIMENT_TRAINING_DATA]
            labels = [self.sentiment_labels.index(data[1]) for data in SENTIMENT_TRAINING_DATA] # 將標籤轉換為數字索引

            self.pipeline = Pipeline([
                ('tfidf', TfidfVectorizer()),
                ('clf', LinearSVC(random_state=42)) # 加入 random_state
            ])
            self.pipeline.fit(texts, labels)

            joblib.dump(self.pipeline, self.model_path)
            logger.info("Sentiment model trained and saved successfully.")
        except Exception as e:
            raise ModelLoadingError(model_name="Sentiment", detail=f"Training failed: {e}")

    def analyze_sentiment(self, text: str) -> Tuple[str, float]:
        if not self.pipeline:
            raise ModelLoadingError(model_name="Sentiment", detail="Model not initialized.")
        if not text.strip():
            raise PredictionError(model_name="Sentiment", detail="Input text for analysis cannot be empty.")

        try:
            # LinearSVC 不直接提供 predict_proba，這裡模擬一個 confidence score
            # 對於需要概率的場景，可以考慮使用 LogisticRegression 或其他支持概率輸出的分類器
            predicted_label_idx = self.pipeline.predict([text])[0]
            sentiment_label = self.sentiment_labels[predicted_label_idx]
            
            # 簡單模擬置信度，實際應用中需要模型本身的支持
            # 對於基於 SVM 的模型，可以考慮使用 decision_function 的絕對值來作為置信度參考
            # 或者轉換為概率 (雖然不直接，但有些庫提供方法)
            # 這裡我們給一個基於標籤的預設高置信度
            confidence = 0.9 if sentiment_label in ["positive", "negative"] else 0.7 

            logger.debug(f"Analyzed sentiment for '{text}': {sentiment_label} (Score: {confidence:.2f})")
            return sentiment_label, float(confidence)
        except Exception as e:
            raise PredictionError(model_name="Sentiment", detail=f"Prediction failed: {e}")

# 實例化服務 (單例模式)
sentiment_service = SentimentService()
EOF

# fastapi-ai-service/app/api/sentiment_api.py (路由層)
cat << 'EOF' > "$FASTAPI_DIR/app/api/sentiment_api.py"
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
EOF

# fastapi-ai-service/app/services/dispatch_service.py
cat << 'EOF' > "$FASTAPI_DIR/app/services/dispatch_service.py"
import logging
from typing import Dict, Any, Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
import joblib
import os
from app.services.exceptions import ModelLoadingError, PredictionError

logger = logging.getLogger(__name__)

# 模擬客服人員/部門列表 (這些 ID 應該對應到 Laravel 資料庫中的客服人員 ID)
AGENTS = {
    1: {"name": "技術支援部", "categories": ["technical", "login", "software", "account_lock"], "is_senior": False},
    2: {"name": "帳務部門", "categories": ["billing", "payment", "invoice", "refund"], "is_senior": False},
    3: {"name": "售後服務部", "categories": ["warranty", "return", "delivery", "product_defect"], "is_senior": False},
    4: {"name": "綜合客服部", "categories": ["general", "other", "inquiry"], "is_senior": True}, # 假設綜合客服部有資深客服
    5: {"name": "資深技術支援", "categories": ["technical"], "is_senior": True} # 額外定義一個資深技術客服
}

# 模擬工單分類訓練數據
DISPATCH_TRAINING_DATA = [
    ("我的帳號無法登入", "technical"),
    ("軟體出現bug了", "technical"),
    ("忘記密碼", "technical"),
    ("帳戶被鎖定怎麼辦", "account_lock"), # 新增帳戶鎖定類別
    ("訂單支付失敗", "billing"),
    ("關於我的帳單問題", "billing"),
    ("我想申請退款", "billing"), # 退款可能和帳務也可能和售後有關，需要判斷上下文
    ("商品有瑕疵，要怎麼退貨？", "product_defect"),
    ("我想詢問產品保修政策", "product_defect"),
    ("我的包裹物流異常", "delivery"),
    ("我只是想問個問題", "general"),
    ("感謝你們的服務", "general"),
    ("我想知道你們的營業時間", "general"),
    ("請問有最新的優惠活動嗎", "general"),
]

class DispatchService:
    _instance = None
    _is_initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DispatchService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._is_initialized:
            self.model_dir = os.getenv("MODEL_DIR", "/app/models")
            self.vectorizer_path = os.path.join(self.model_dir, "dispatch_vectorizer.pkl")
            self.model_path = os.path.join(self.model_dir, "dispatch_model.pkl")
            self.categories = sorted(list(set([label for _, label in DISPATCH_TRAINING_DATA])))
            self.vectorizer = None
            self.model = None
            self._load_or_train_model()
            self._is_initialized = True

    def _load_or_train_model(self):
        os.makedirs(self.model_dir, exist_ok=True)
        if os.path.exists(self.vectorizer_path) and os.path.exists(self.model_path):
            try:
                self.vectorizer = joblib.load(self.vectorizer_path)
                self.model = joblib.load(self.model_path)
                if not hasattr(self.vectorizer, 'transform') or not hasattr(self.model, 'predict'):
                    raise ValueError("Loaded model or vectorizer is not valid.")
                logger.info("Dispatch model loaded from disk.")
            except Exception as e:
                logger.warning(f"Failed to load dispatch model (may be corrupted or outdated): {e}. Training new one.")
                self._train_and_save_model()
        else:
            logger.info("Dispatch model not found on disk. Training new one.")
            self._train_and_save_model()

    def _train_and_save_model(self):
        try:
            texts = [data[0] for data in DISPATCH_TRAINING_DATA]
            labels = [data[1] for data in DISPATCH_TRAINING_DATA]

            self.vectorizer = TfidfVectorizer()
            X = self.vectorizer.fit_transform(texts)
            y = [self.categories.index(label) for label in labels]

            self.model = MultinomialNB() # 簡單的分類器
            self.model.fit(X, y)

            joblib.dump(self.vectorizer, self.vectorizer_path)
            joblib.dump(self.model, self.model_path)
            logger.info("Dispatch model trained and saved successfully.")
        except Exception as e:
            raise ModelLoadingError(model_name="Dispatch", detail=f"Training failed: {e}")

    def predict_category(self, message: str) -> Tuple[str, float]:
        if not self.model or not self.vectorizer:
            raise ModelLoadingError(model_name="Dispatch", detail="Model not initialized.")
        if not message.strip():
            raise PredictionError(model_name="Dispatch", detail="Input message for prediction cannot be empty.")
        try:
            message_vectorized = self.vectorizer.transform([message])
            probabilities = self.model.predict_proba(message_vectorized)[0]
            predicted_category_idx = self.model.predict(message_vectorized)[0]
            
            category = self.categories[predicted_category_idx]
            confidence = probabilities[predicted_category_idx]
            
            logger.debug(f"Predicted category for '{message[:50]}': {category} (Confidence: {confidence:.2f})")
            return category, float(confidence)
        except Exception as e:
            raise PredictionError(model_name="Dispatch", detail=f"Prediction failed: {e}")

    def get_recommended_agent(self, category: str, sentiment: str) -> Tuple[int, str, str]:
        """
        根據預測類別和情感推薦客服人員。
        返回 (agent_id, category_name, reason)
        """
        # 預設為綜合客服部，通常綜合客服部處理範圍廣且可能包含資深客服
        default_agent_id = 4 
        recommended_agent_id = default_agent_id 
        assigned_category = category # 默認分配給預測的類別
        reason = f"Based on message content classification ({category})."

        # 優先尋找與類別匹配的客服
        for agent_id, agent_info in AGENTS.items():
            if category in agent_info["categories"]:
                recommended_agent_id = agent_id
                break
        
        # 如果是負面情緒，嘗試轉接給資深客服 (如果存在資深客服且與類別相關)
        if sentiment == "negative":
            reason += " (Elevated priority due to negative sentiment.)"
            # 優先考慮該類別的資深客服，如果沒有，轉給綜合客服部的資深客服
            found_senior_agent = False
            for agent_id, agent_info in AGENTS.items():
                if agent_info["is_senior"] and category in agent_info["categories"]:
                    recommended_agent_id = agent_id
                    found_senior_agent = True
                    break
            
            if not found_senior_agent and AGENTS[default_agent_id]["is_senior"]:
                recommended_agent_id = default_agent_id # 轉給綜合客服部的資深客服

        return recommended_agent_id, assigned_category.capitalize(), reason

# 實例化服務 (單例模式)
dispatch_service = DispatchService()
EOF

# fastapi-ai-service/app/api/dispatch_api.py (路由層)
cat << 'EOF' > "$FASTAPI_DIR/app/api/dispatch_api.py"
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
EOF

# fastapi-ai-service/data/knowledge_base.json
cat << 'EOF' > "$FASTAPI_DIR/data/knowledge_base.json"
[
    {"id": 1, "question": "如何重置我的帳戶密碼？", "answer": "您可以訪問我們的登入頁面，點擊“忘記密碼”，然後按照指示操作。", "keywords": ["密碼", "重置", "帳戶", "忘記", "登入問題"]},
    {"id": 2, "question": "我的訂單什麼時候會發貨？", "answer": "通常情況下，訂單會在2個工作日內發貨。您可以在訂單詳情頁面查看物流信息。", "keywords": ["訂單", "發貨", "物流", "送貨"]},
    {"id": 3, "question": "如何申請退款？", "answer": "請在收到商品後7天內聯繫我們的客服，提供訂單號碼和退款原因。退款將在3-5個工作日內處理。", "keywords": ["退款", "申請", "退貨", "取消訂單", "錢"]},
    {"id": 4, "question": "如何聯繫人工客服？", "answer": "您可以透過撥打客服熱線或在聊天頁面點擊“轉接人工”來聯繫我們。", "keywords": ["聯繫", "人工", "客服", "電話", "轉接"]},
    {"id": 5, "question": "如何更新我的個人資料？", "answer": "請登入您的帳戶，進入“設定”或“個人資料”頁面進行修改。", "keywords": ["更新", "資料", "個人", "修改"]},
    {"id": 6, "question": "我的產品有問題，如何保修？", "answer": "請提供您的訂單號和問題描述，我們將根據產品保修政策為您處理。請先訪問保修政策頁面了解詳情。", "keywords": ["保修", "維修", "產品", "損壞", "質量"]},
    {"id": 7, "question": "如何啟用我的新帳戶？", "answer": "新帳戶通常會發送一封啟用郵件到您的註冊信箱，請點擊郵件中的連結完成啟用。", "keywords": ["啟用", "新帳戶", "註冊", "驗證"]},
    {"id": 8, "question": "你們的營業時間是幾點到幾點？", "answer": "我們的客服服務時間是週一至週五上午9點至下午6點（當地時間）。", "keywords": ["營業時間", "客服時間", "工作時間"]},
    {"id": 9, "question": "付款失敗怎麼辦？", "answer": "請檢查您的支付資訊是否正確，或嘗試更換支付方式。如果問題持續，請聯繫您的銀行或我們的帳務部門。", "keywords": ["付款", "支付", "失敗", "銀行", "帳務"]}
]
EOF

# fastapi-ai-service/app/services/knowledge_base_service.py
cat << 'EOF' > "$FASTAPI_DIR/app/services/knowledge_base_service.py"
import logging
import json
import os
from typing import List, Dict, Any, Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from app.services.exceptions import ModelLoadingError, PredictionError, ResourceNotFoundError

logger = logging.getLogger(__name__)

class KnowledgeBaseService:
    _instance = None
    _is_initialized = False

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(KnowledgeBaseService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if not self._is_initialized:
            self.kb_path = os.getenv("KNOWLEDGE_BASE_PATH", "/app/data/knowledge_base.json")
            self.knowledge_base_data: List[Dict[str, Any]] = []
            self.vectorizer = None
            self.kb_vectors = None
            self._load_and_process_knowledge_base()
            self._is_initialized = True

    def _load_and_process_knowledge_base(self):
        """
        Load knowledge base data from JSON and vectorize it.
        This method handles initial loading and can be extended for refresh logic.
        """
        try:
            if not os.path.exists(self.kb_path):
                # 如果文件不存在，可以選擇創建一個空文件或拋出錯誤
                logger.warning(f"Knowledge base file not found at {self.kb_path}. Creating an empty one.")
                os.makedirs(os.path.dirname(self.kb_path), exist_ok=True)
                with open(self.kb_path, 'w', encoding='utf-8') as f:
                    json.dump([], f, ensure_ascii=False, indent=4)
                self.knowledge_base_data = [] # 確保數據為空列表
                return
            
            with open(self.kb_path, 'r', encoding='utf-8') as f:
                self.knowledge_base_data = json.load(f)
            
            if not self.knowledge_base_data:
                logger.warning("Knowledge base data is empty. Search functionality will return no matches.")
                return

            # 使用問題和關鍵詞來訓練向量器
            texts_to_vectorize = [item['question'] + " ".join(item.get('keywords', [])) for item in self.knowledge_base_data]
            
            self.vectorizer = TfidfVectorizer()
            self.kb_vectors = self.vectorizer.fit_transform(texts_to_vectorize)
            logger.info(f"Knowledge base loaded and vectorized successfully from {self.kb_path}.")

        except json.JSONDecodeError as e:
            logger.error(f"Error decoding knowledge base JSON from {self.kb_path}: {e}. Please check file format.")
            raise ModelLoadingError(model_name="Knowledge Base", detail=f"Invalid JSON format: {e}")
        except Exception as e:
            logger.error(f"Unexpected error loading knowledge base from {self.kb_path}: {e}")
            raise ModelLoadingError(model_name="Knowledge Base", detail=f"Loading failed: {e}")

    def search_knowledge_base(self, query: str, top_n: int = 3) -> List[Dict[str, Any]]:
        """
        Searches the knowledge base for the most relevant answers based on query.
        """
        if not self.knowledge_base_data:
            logger.info("Knowledge base is empty, returning no matches.")
            return []
        if not self.vectorizer or self.kb_vectors is None:
            # 如果因為某些原因模型未初始化，嘗試重新加載
            logger.warning("Knowledge base vectorizer or vectors not initialized. Attempting to reload.")
            self._load_and_process_knowledge_base()
            if not self.vectorizer or self.kb_vectors is None: # 如果重新加載仍然失敗
                raise ModelLoadingError(model_name="Knowledge Base Search", detail="Knowledge base system not ready.")
        
        if not query.strip():
            logger.warning("Query for knowledge base search is empty, returning no matches.")
            return []

        try:
            query_vector = self.vectorizer.transform([query])
            similarities = cosine_similarity(query_vector, self.kb_vectors).flatten()
            
            # 根據相似度排序
            sorted_indices = similarities.argsort()[::-1]
            
            matches = []
            for idx in sorted_indices:
                score = float(similarities[idx])
                # 設定一個相似度閾值，可調，避免返回不相關的結果
                if score > 0.2: 
                    item = self.knowledge_base_data[idx]
                    matches.append({
                        "id": item['id'],
                        "question": item['question'],
                        "answer": item['answer'],
                        "score": round(score, 4)
                    })
                if len(matches) >= top_n:
                    break
            
            logger.debug(f"Knowledge base search for '{query}': found {len(matches)} matches.")
            return matches
        except Exception as e:
            raise PredictionError(model_name="Knowledge Base Search", detail=f"Search failed: {e}")

    def refresh_knowledge_base(self):
        """
        Refreshes the knowledge base by reloading data and re-vectorizing.
        This could be called periodically or via an admin API endpoint.
        """
        logger.info("Refreshing knowledge base...")
        self.knowledge_base_data = [] # Clear existing data
        self.vectorizer = None
        self.kb_vectors = None
        self._load_and_process_knowledge_base()
        logger.info("Knowledge base refresh complete.")

# 實例化服務 (單例模式)
knowledge_base_service = KnowledgeBaseService()
EOF

# fastapi-ai-service/app/api/knowledge_base_api.py (路由層)
cat << 'EOF' > "$FASTAPI_DIR/app/api/knowledge_base_api.py"
from fastapi import APIRouter, status
from pydantic import BaseModel
import logging
from typing import List, Dict, Any
from app.services.knowledge_base_service import knowledge_base_service # 導入服務實例
from app.services.exceptions import InvalidInputError, APIException, ResourceNotFoundError

router = APIRouter()
logger = logging.getLogger(__name__)

class KnowledgeSearchRequest(BaseModel):
    query: str
    top_n: int = 3

class KnowledgeMatch(BaseModel):
    id: int
    question: str
    answer: str
    score: float

class KnowledgeSearchResponse(BaseModel):
    matches: List[KnowledgeMatch]

@router.post("/", response_model=KnowledgeSearchResponse)
async def get_knowledge_recommendations(request: KnowledgeSearchRequest):
    """
    分析客戶問題，從知識庫中查找最相關的 FAQ 或解決方案。
    """
    if not request.query or not request.query.strip():
        raise InvalidInputError(detail="Query text cannot be empty or just whitespace.")
    if request.top_n <= 0:
        raise InvalidInputError(detail="top_n must be a positive integer.")

    try:
        matches = knowledge_base_service.search_knowledge_base(request.query, request.top_n)
        return KnowledgeSearchResponse(matches=matches)
    except APIException as e:
        raise e
    except Exception as e:
        logger.exception("Unexpected error in knowledge base API.")
        raise APIException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, message="Failed to search knowledge base.", code="KB_SEARCH_ERROR")

@router.post("/refresh", status_code=status.HTTP_200_OK)
async def refresh_knowledge_base():
    """
    Refresh (reload and re-vectorize) the knowledge base.
    This can be used after updating the knowledge_base.json file.
    """
    try:
        knowledge_base_service.refresh_knowledge_base()
        return {"message": "Knowledge base refreshed successfully."}
    except APIException as e:
        raise e
    except Exception as e:
        logger.exception("Failed to refresh knowledge base.")
        raise APIException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, message="Failed to refresh knowledge base.", code="KB_REFRESH_ERROR")
EOF

# fastapi-ai-service/tests/test_chatbot_service.py (測試骨架)
cat << 'EOF' > "$FASTAPI_DIR/tests/test_chatbot_service.py"
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
EOF

# FastAPI Dockerfile (更新依賴和 CMD)
cat << 'EOF' > "$FASTAPI_DIR/Dockerfile"
FROM python:3.10-slim-buster

# 設置環境變量，確保 Python stdout/stderr 不被緩衝
ENV PYTHONUNBUFFERED 1

WORKDIR /app

# 複製 requirements.txt 並安裝依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 創建用於存放模型的目錄 (映射到 Docker volume)
RUN mkdir -p /app/models
# 創建用於存放知識庫的數據目錄 (映射到 Docker volume)
RUN mkdir -p /app/data

# 複製應用程式代碼
COPY . .

EXPOSE 8001

# 運行 Uvicorn 服務
# --reload 在生產環境中通常不建議使用，只用於開發
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
EOF

echo "FastAPI + AI 服務骨架生成完成。"

echo "正在生成 Docker Compose 配置..."
cat << 'EOF' > "$PROJECT_NAME/docker-compose.yml"
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php-fpm
      - fastapi-ai

  php-fpm:
    build:
      context: ./laravel-backend
      dockerfile: Dockerfile
    volumes:
      - ./laravel-backend:/var/www/html
    environment:
      # Laravel .env 設定 (這些會覆蓋 .env 檔案中的同名變數)
      DB_CONNECTION: mysql
      DB_HOST: mysql
      DB_PORT: 3306
      DB_DATABASE: your_database_name # <<< 請修改
      DB_USERNAME: your_db_user      # <<< 請修改
      DB_PASSWORD: your_db_password  # <<< 請修改
      REDIS_HOST: redis
      QUEUE_CONNECTION: redis # 確保 Laravel 使用 Redis 隊列
      FASTAPI_AI_SERVICE_URL: http://fastapi-ai:8001 # 容器內部通訊
      # WEBHOOK_SECRET_KEY: your_webhook_secret_key # 如果實現 Webhook 簽名驗證，請配置
    depends_on:
      - mysql
      - redis
    # network_mode: host # 如果在某些情況下需要 host 網路

  fastapi-ai:
    build:
      context: ./fastapi-ai-service
      dockerfile: Dockerfile
    volumes:
      - ./fastapi-ai-service:/app
      # 持久化 AI 模型和知識庫數據，確保容器重建時不會丟失訓練結果
      - models_data:/app/models # 持久化 AI 模型
      - knowledge_data:/app/data # 持久化知識庫數據
    ports:
      - "8001:8001" # 外部訪問 AI 服務的端口
    environment:
      PYTHONUNBUFFERED: 1 # 確保日誌輸出
      MODEL_DIR: /app/models # AI 模型文件夾路徑 (對應到 volume)
      KNOWLEDGE_BASE_PATH: /app/data/knowledge_base.json # 知識庫文件路徑 (對應到 volume)
    # network_mode: host # 如果在某些情況下需要 host 網路

  mysql:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: your_root_password # <<< 請修改
      MYSQL_DATABASE: your_database_name    # <<< 請修改
      MYSQL_USER: your_db_user              # <<< 請修改
      MYSQL_PASSWORD: your_db_password      # <<< 請修改
    volumes:
      - db_data:/var/lib/mysql # 持久化數據
    command: --default-authentication-plugin=mysql_native_password # MySQL 8 兼容性

  redis:
    image: redis:latest
    ports:
      - "6379:6379"

volumes:
  db_data: # 定義一個數據卷用於持久化 MySQL 數據
  models_data: # 定義一個數據卷用於持久化 AI 模型
  knowledge_data: # 定義一個數據卷用於持久化知識庫
EOF
echo "Docker Compose 配置生成完成。"

echo "正在生成 Nginx 配置..."
cat << 'EOF' > "$NGINX_DIR/nginx.conf"
# nginx/nginx.conf
server {
    listen 80;
    server_name localhost;
    root /var/www/html/public; # Laravel public 目錄

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    index index.php index.html index.htm;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php-fpm:9000; # 轉發 PHP 請求到 php-fpm 服務
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\. {
        deny all; # 拒絕訪問隱藏文件
    }
}
EOF
echo "Nginx 配置生成完成。"

echo ""
echo "==================================================="
echo "  專案骨架已成功建立在 '$PROJECT_NAME' 目錄下！"
echo "  這是最終增強版，內建了更多生產級別的優化考量。"
echo "==================================================="
echo ""
echo "下一步操作 (請仔細閱讀 README.md):"
echo "1. 進入專案目錄: cd $PROJECT_NAME"
echo "2. **重要**: 編輯 $LARAVEL_DIR/.env.example 和 $FASTAPI_DIR/.env.example，複製為 .env，並修改資料庫密碼等敏感資訊。"
echo "   請確保 docker-compose.yml 中對應的環境變數與 .env 檔案中設定的資料庫資訊一致。"
echo "3. **重要**: 編輯 $LARAVEL_DIR/database/migrations/*.php.example 文件，將其內容複製到你通過 'php artisan make:model -m' 命令生成的實際 migration 文件中。"
echo "4. **重要**: 複製 $FASTAPI_DIR/data/knowledge_base.json 到新創建的 Docker volume 掛載點 (即 `$PROJECT_NAME/knowledge_data/knowledge_base.json`)。"
echo "   第一次運行 Docker Compose 會自動創建 `knowledge_data` 目錄，然後你手動將 `knowledge_base.json` 複製進去。"
echo "   範例指令: cp $FASTAPI_DIR/data/knowledge_base.json $PROJECT_NAME/knowledge_data/knowledge_base.json"
echo "5. 構建並啟動 Docker 容器: docker compose up -d --build"
echo "   第一次啟動時，FastAPI 服務會自動訓練並保存 AI 模型到 `$PROJECT_NAME/models_data/` 目錄中。"
echo "6. 進入 Laravel 容器內部完成依賴安裝和配置 (請參考 README.md 中的詳細步驟):"
echo "   docker compose exec php-fpm bash"
echo "   composer install"
echo "   php artisan key:generate"
echo "   php artisan migrate --seed (可選，用於填充初始數據)"
echo "   npm install && npm run dev (如果 Laravel 專案有前端)"
echo "   exit"
echo "7. 訪問應用: Laravel 應用在 http://localhost，FastAPI 文檔在 http://localhost:8001/docs"
echo ""
echo "祝您開發和面試順利！"