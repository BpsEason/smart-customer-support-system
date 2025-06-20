<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use App\Models\Ticket;
use App\Models\User;
use App\Models\Reply;
use App\Events\MessageReplied;
use App\Mail\CustomerReplyMail; // 假設你建立這個 Mailable
use Illuminate\Support\Facades\Mail;

class ProcessIncomingWebhook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $tries = 3;
    public $backoff = 5;

    protected $messageContent;
    protected $customerIdentifier; // 客戶的唯一識別符，例如 Email
    protected $source; // 訊息來源，例如 'web_chat', 'email', 'line_webhook'

    public function __construct(string $messageContent, string $customerIdentifier, string $source)
    {
        $this->messageContent = $messageContent;
        $this->customerIdentifier = $customerIdentifier;
        $this->source = $source;
    }

    public function handle()
    {
        Log::info('Processing webhook job for customer:', ['id' => $this->customerIdentifier, 'source' => $this->source, 'message' => $this->messageContent]);

        try {
            // 1. 獲取或創建客戶 (假設使用 Email 作為唯一識別)
            // 假設 'customer' 是默認角色
            $user = User::firstOrCreate(
                ['email' => $this->customerIdentifier],
                ['name' => $this->customerIdentifier, 'password' => \Illuminate\Support\Facades\Hash::make(\Illuminate\Support\Str::random(10)), 'role' => 'customer']
            );

            // 2. 調用 FastAPI AI 服務
            $aiServiceApiKey = env('AI_SERVICE_API_KEY');
            $aiResponse = Http::timeout(30)
                ->withHeaders([
                    'X-API-KEY' => $aiServiceApiKey, // 添加 API 金鑰頭
                ])
                ->post(env('FASTAPI_AI_SERVICE_URL') . '/ai/process_message', [
                    'message' => $this->messageContent,
                    'customer_id' => $this->customerIdentifier,
                    'source' => $this->source,
                ])->json();

            // 3. 獲取或創建工單
            // 查找客戶是否有開啟中 (pending, assigned, in_progress, replied) 的工單
            $ticket = Ticket::where('customer_id', $user->id)
                            ->whereIn('status', ['pending', 'assigned', 'in_progress', 'replied'])
                            ->orderBy('updated_at', 'desc')
                            ->first();

            if (!$ticket) {
                // 如果沒有活躍工單，則創建一個新工單
                $ticket = Ticket::create([
                    'customer_id' => $user->id,
                    'subject' => $aiResponse['intent'] ?? '來自 ' . $this->source . ' 的新訊息',
                    'description' => $this->messageContent, // 原始訊息作為描述
                    'status' => 'pending',
                    'priority' => ($aiResponse['sentiment'] ?? 'neutral') === 'negative' ? 'high' : 'normal',
                    'assigned_to' => User::where('name', $aiResponse['assigned_agent'])->first()->id ?? null,
                    'source_channel' => $this->source,
                ]);
                Log::info('New ticket created:', ['ticket_id' => $ticket->id, 'subject' => $ticket->subject]);
            } else {
                // 如果有活躍工單，更新主題，如果AI提供更精確的意圖
                if (isset($aiResponse['intent']) && $aiResponse['intent'] !== 'fallback') {
                    $ticket->subject = $aiResponse['intent'];
                    $ticket->save();
                }
                Log::info('Existing ticket found and potentially updated:', ['ticket_id' => $ticket->id]);
            }

            // 4. 記錄客戶的原始訊息作為回覆
            $ticket->replies()->create([
                'user_id' => $user->id, // 客戶發送
                'content' => $this->messageContent,
                'is_ai_reply' => false,
                'reply_from_source' => $this->source,
            ]);

            // 5. 處理 AI 自動回覆 (如果 AI 有給出回覆)
            $aiReplyText = $aiResponse['chatbot_reply'] ?? null;
            if ($aiReplyText) {
                // 記錄 AI 回覆到工單歷史中
                $reply = $ticket->replies()->create([
                    'user_id' => null, // 表示是系統/AI 回覆
                    'content' => $aiReplyText,
                    'is_ai_reply' => true,
                    'reply_from_source' => 'system_ai',
                ]);

                // 根據訊息來源，將 AI 回覆發送給客戶
                switch ($this->source) {
                    case 'web_chat':
                        // 對於即時聊天，通過 WebSocket 廣播回覆
                        event(new MessageReplied(
                            $this->customerIdentifier, // 廣播給哪個客戶 (使用其唯一識別符)
                            $aiReplyText,
                            'AI 客服' // 發送者名稱
                        ));
                        Log::info('AI reply broadcasted for web_chat:', ['customer' => $this->customerIdentifier, 'reply' => $aiReplyText]);
                        break;
                    case 'email': // 從表單提交的 Email 
                        // 對於 Email 來源，可以異步發送 Email 回覆
                        Mail::to($user->email)->send(new CustomerReplyMail($ticket, $reply));
                        Log::info('AI reply email dispatched:', ['customer' => $this->customerIdentifier, 'reply' => $aiReplyText]);
                        break;
                    case 'line_webhook':
                        // 如果有 LINE 整合，調用 LINE Messaging API 發送回覆
                        // 假設 LineMessagingService::sendReply($user->line_user_id, $aiReplyText);
                        Log::info('AI reply to LINE customer:', ['customer' => $this->customerIdentifier, 'reply' => $aiReplyText]);
                        break;
                    default:
                        Log::warning('Unhandled source channel for AI reply:', ['source' => $this->source]);
                        break;
                }

                // 如果 AI 回覆了，且意圖是可以自行解決的，可以嘗試關閉工單
                if (isset($aiResponse['intent']) && in_array($aiResponse['intent'], ['goodbye', 'self_service_solved'])) {
                    $ticket->status = 'resolved';
                    $ticket->resolved_by = 'AI';
                    $ticket->save();
                    Log::info('Ticket resolved by AI:', ['ticket_id' => $ticket->id]);
                } else if ($ticket->status === 'pending' && $aiReplyText) {
                    // 如果工單仍然是 pending 並且 AI 提供了回覆，可以將其標記為已回覆
                    $ticket->status = 'replied';
                    $ticket->save();
                }

            }

            // 6. 更新工單的優先級和分配情況 (如果 AI 提供了建議)
            $originalPriority = $ticket->priority;
            $originalAssignedTo = $ticket->assigned_to;

            if (($aiResponse['sentiment'] ?? 'neutral') === 'negative' && $ticket->priority !== 'urgent') {
                $ticket->priority = 'urgent';
            } else if (($aiResponse['sentiment'] ?? 'neutral') !== 'negative' && $ticket->priority === 'urgent') {
                 $ticket->priority = 'normal'; // 降低優先級如果情緒轉好
            }


            // 只有當 AI 建議分配給某人且目前未分配時才分配
            if (isset($aiResponse['assigned_agent']) && $aiResponse['assigned_agent'] && !$ticket->assigned_to) {
                $assignedUser = User::where('name', $aiResponse['assigned_agent'])->first();
                if ($assignedUser) {
                    $ticket->assigned_to = $assignedUser->id;
                    $ticket->status = 'assigned'; // 如果分配了，更新狀態
                }
            }

            if ($ticket->isDirty('priority') || $ticket->isDirty('assigned_to') || $ticket->isDirty('status')) {
                 $ticket->save();
                 Log::info('Ticket attributes updated by AI analysis:', [
                     'ticket_id' => $ticket->id,
                     'old_priority' => $originalPriority, 'new_priority' => $ticket->priority,
                     'old_assigned_to' => $originalAssignedTo, 'new_assigned_to' => $ticket->assigned_to,
                     'new_status' => $ticket->status
                 ]);
            }


            Log::info('Webhook job processed successfully for ticket:', ['id' => $ticket->id, 'ai_response_summary' => ['intent' => $aiResponse['intent'], 'sentiment' => $aiResponse['sentiment'], 'chatbot_reply_len' => strlen($aiReplyText ?? '')]]);

        } catch (\Illuminate\Http\Client\RequestException $e) {
            // 處理 HTTP 請求失敗 (例如 FastAPI 服務不響應或返回錯誤)
            Log::error('FastAPI AI service call failed:', ['error' => $e->getMessage(), 'response_body' => $e->response?->body(), 'status' => $e->response?->status(), 'trace' => $e->getTraceAsString()]);
            // 可以選擇在此處創建一個緊急工單或發送通知給管理員
            $this->createEmergencyTicket($this->customerIdentifier, $this->messageContent, "AI 服務呼叫失敗: " . $e->getMessage(), $this->source);
            throw $e; // 讓佇列重試，或根據策略決定是否不再重試
        } catch (\Exception $e) {
            // 處理其他一般錯誤
            Log::error('Error processing webhook job:', ['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
            $this->createEmergencyTicket($this->customerIdentifier, $this->messageContent, "處理訊息時發生內部錯誤: " . $e->getMessage(), $this->source);
            throw $e;
        }
    }

    /**
     * Job 失敗時的處理方法。
     */
    public function failed(\Throwable $exception)
    {
        Log::error('ProcessIncomingWebhook job failed after retries:', [
            'message_content' => $this->messageContent,
            'customer_identifier' => $this->customerIdentifier,
            'source' => $this->source,
            'exception' => $exception->getMessage(),
            'trace' => $exception->getTraceAsString(),
        ]);
        // 在最終失敗時，確保創建一個工單或通知人工客服介入
        $this->createEmergencyTicket($this->customerIdentifier, $this->messageContent, "訊息處理失敗 (多次重試後): " . $exception->getMessage(), $this->source);
        // 可以發送失敗通知給開發者或客服
        // \Mail::to('dev_team@example.com')->send(new JobFailedNotification($this->messageContent, $exception));
    }

    /**
     * 當 AI 服務呼叫失敗或 Job 最終失敗時，創建緊急工單。
     */
    protected function createEmergencyTicket(string $customerIdentifier, string $messageContent, string $errorMessage, string $sourceChannel)
    {
        try {
            $user = User::firstOrCreate(
                ['email' => $customerIdentifier],
                ['name' => $customerIdentifier, 'password' => \Illuminate\Support\Facades\Hash::make(\Illuminate\Support\Str::random(10)), 'role' => 'customer']
            );

            Ticket::create([
                'customer_id' => $user->id,
                'subject' => '緊急工單：訊息處理失敗',
                'description' => "客戶原始訊息：\n" . $messageContent . "\n\n錯誤詳情：\n" . $errorMessage,
                'status' => 'pending',
                'priority' => 'urgent', // 高優先級
                'assigned_to' => null, // 可以設定一個默認的緊急處理組 ID
                'source_channel' => $sourceChannel . '_error',
            ]);
            Log::info('Emergency ticket created due to processing failure.', ['customer_id' => $customerIdentifier, 'error' => $errorMessage]);
        } catch (\Exception $e) {
            Log::critical('Failed to create emergency ticket:', ['original_error' => $errorMessage, 'creation_error' => $e->getMessage()]);
        }
    }
}
