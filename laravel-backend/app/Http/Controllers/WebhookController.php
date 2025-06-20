<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Jobs\ProcessIncomingWebhook; // 確保引入 Job

class WebhookController extends Controller
{
    /**
     * 處理來自外部系統的 incoming 訊息 (例如：Web 聊天、Email 表單、Line Bot 等)
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function handleIncoming(Request $request)
    {
        // 記錄接收到的 webhook 數據
        Log::info('Received incoming webhook:', $request->all());

        // 簡單驗證，根據實際系統調整
        $request->validate([
            'message' => 'required|string|max:5000',
            'customer_id' => 'required|string|max:255', // 例如客戶的 Email
            'source' => 'required|string|in:web_chat,email,line_webhook,other', // 訊息來源
            // 可以添加更多驗證，例如簽名驗證等
        ]);

        // 將訊息推送到佇列中進行異步處理
        ProcessIncomingWebhook::dispatch(
            $request->input('message'),
            $request->input('customer_id'),
            $request->input('source')
        );

        return response()->json(['status' => 'Message received and queued for processing.'], 202);
    }
}
