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
