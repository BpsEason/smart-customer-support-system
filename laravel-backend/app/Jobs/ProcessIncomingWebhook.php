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
