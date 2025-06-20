<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Ticket;
use App\Models\User;
use App\Models\Reply;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use App\Events\MessageReplied; // 引入廣播事件
use App\Mail\CustomerReplyMail; // 假設你建立這個 Mailable
use Illuminate\Support\Facades\Mail;


class TicketController extends Controller
{
    /**
     * 獲取所有工單（供儀表板和客服使用）。
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        $tickets = Ticket::with(['customer', 'assignee'])->orderBy('updated_at', 'desc')->get();
        return response()->json($tickets);
    }

    /**
     * 顯示單個工單及其所有回覆。
     *
     * @param  \App\Models\Ticket  $ticket
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Ticket $ticket)
    {
        $ticket->load(['customer', 'assignee', 'replies' => function($query) {
            $query->orderBy('created_at', 'asc')->with('user'); // 載入回覆及其發送者
        }]);
        return response()->json($ticket);
    }

    /**
     * 處理客服對工單的回覆。
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Ticket  $ticket
     * @return \Illuminate\Http\JsonResponse
     */
    public function replyToTicket(Request $request, Ticket $ticket)
    {
        $request->validate([
            'reply_content' => 'required|string|max:5000',
        ]);

        // 確保只有登入的客服可以回覆 (根據您的授權策略調整)
        if (!Auth::check() || (Auth::user()->role !== 'agent' && Auth::user()->role !== 'admin')) {
             return response()->json(['message' => 'Unauthorized to reply to tickets.'], 403);
        }

        // 記錄客服回覆到工單歷史
        $reply = $ticket->replies()->create([
            'user_id' => Auth::id(), // 當前登入的客服 ID
            'content' => $request->reply_content,
            'is_ai_reply' => false,
            'reply_from_source' => 'agent', // 標識為人工客服回覆
        ]);

        // **核心：根據工單的來源渠道，將回覆發送給客戶**
        $customer = $ticket->customer; // 獲取客戶模型
        if ($customer) {
            $customerIdentifier = $customer->email; // 客戶的唯一識別符

            switch ($ticket->source_channel) {
                case 'web_chat':
                    // 如果是網頁即時聊天，通過 WebSocket 廣播回覆
                    event(new MessageReplied(
                        $customerIdentifier,
                        $request->reply_content,
                        Auth::user()->name ?? '客服' // 發送者姓名
                    ));
                    Log::info('Agent reply broadcasted to web_chat:', ['customer' => $customerIdentifier, 'reply' => $request->reply_content]);
                    break;
                case 'email':
                    // 如果是 Email 工單，發送 Email 回覆
                    // 這裡應使用 Laravel Mailer 發送郵件
                    // 確保你已經定義了 App\Mail\CustomerReplyMail Mailable
                    Mail::to($customer->email)->send(new CustomerReplyMail($ticket, $reply));
                    Log::info('Agent reply email dispatched:', ['customer' => $customerIdentifier, 'reply' => $request->reply_content]);
                    break;
                case 'line_webhook':
                    // 如果是 LINE 訊息，調用 LINE Messaging API 回覆
                    // 假設你有名為 LineMessagingService 的服務來處理 LINE API
                    // LineMessagingService::sendReply($customer->line_user_id, $request->reply_content);
                    Log::info('Agent reply to LINE customer:', ['customer' => $customerIdentifier, 'reply' => $request->reply_content]);
                    break;
                default:
                    Log::warning('Unhandled source channel for ticket reply:', ['ticket_id' => $ticket->id, 'source' => $ticket->source_channel]);
                    break;
            }
        } else {
            Log::warning('Customer not found for ticket when attempting to reply:', ['ticket_id' => $ticket->id]);
        }

        // 更新工單狀態，例如改為「已回覆」
        $ticket->status = 'replied';
        $ticket->save();

        return response()->json(['message' => 'Reply sent successfully.', 'reply' => $reply->load('user')]);
    }

    /**
     * 創建一個新工單 (可手動或由系統根據 AI 分析結果自動創建)。
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        $request->validate([
            'customer_id' => 'required|exists:users,id',
            'subject' => 'required|string|max:255',
            'description' => 'nullable|string',
            'priority' => 'in:low,normal,high,urgent',
            'assigned_to' => 'nullable|exists:users,id',
            'source_channel' => 'required|string|max:50', // 確保接收來源渠道
        ]);

        $ticket = Ticket::create($request->all());

        // 如果手動創建工單時有提供 description，也作為第一條回覆
        if ($request->filled('description')) {
            $ticket->replies()->create([
                'user_id' => $request->customer_id,
                'content' => $request->description,
                'is_ai_reply' => false,
                'reply_from_source' => $request->source_channel,
            ]);
        }


        return response()->json($ticket, 201);
    }

    /**
     * 更新工單狀態或指派對象。
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Ticket  $ticket
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, Ticket $ticket)
    {
        // 確保只有授權用戶可以更新 (例如客服或管理員)
        if (!Auth::check() || (Auth::user()->role !== 'agent' && Auth::user()->role !== 'admin')) {
             return response()->json(['message' => 'Unauthorized to update tickets.'], 403);
        }

        $request->validate([
            'status' => 'in:pending,assigned,in_progress,replied,resolved,closed',
            'priority' => 'in:low,normal,high,urgent',
            'assigned_to' => 'nullable|exists:users,id',
        ]);

        $ticket->update($request->all());

        return response()->json($ticket);
    }

    /**
     * 刪除工單。
     *
     * @param  \App\Models\Ticket  $ticket
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Ticket $ticket)
    {
        // 確保只有管理員可以刪除
        if (!Auth::check() || Auth::user()->role !== 'admin') {
             return response()->json(['message' => 'Unauthorized to delete tickets.'], 403);
        }
        $ticket->delete();
        return response()->json(null, 204);
    }
}
