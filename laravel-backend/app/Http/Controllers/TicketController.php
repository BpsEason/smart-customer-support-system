<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Ticket;
use App\Models\User;
use App\Models\Reply;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use App\Events\MessageReplied;
use App\Mail\CustomerReplyMail;
use Illuminate\Support\Facades\Mail;
use App\Http\Requests\Ticket\CreateTicketRequest;
use App\Http\Requests\Ticket\ReplyTicketRequest;
use App\Http\Requests\Ticket\UpdateTicketRequest;

class TicketController extends Controller
{
    public function __construct()
    {
        // 確保只有登入用戶可以訪問這些方法
        $this->middleware('auth:sanctum')->except(['store']);
        // 創建工單可以不需認證 (透過 Webhook 或匿名客戶)
    }

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        // 只有客服和管理員能看所有工單，客戶只能看自己的
        if (Auth::user()->role === 'customer') {
            $tickets = Ticket::where('customer_id', Auth::id())->with(['customer', 'assignee'])->orderBy('updated_at', 'desc')->get();
        } else {
            $tickets = Ticket::with(['customer', 'assignee'])->orderBy('updated_at', 'desc')->get();
        }
        return response()->json($tickets);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \App\Http\Requests\Ticket\CreateTicketRequest  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(CreateTicketRequest $request)
    {
        // 如果用戶已登入，將其作為 customer_id
        $customer_id = Auth::check() ? Auth::id() : null;

        // 如果是來自 Webhook，customer_id 會透過請求傳入
        if ($request->filled('customer_external_id')) {
            // 檢查是否存在此 external ID 的客戶，如果沒有則創建
            $customer = User::firstOrCreate(
                ['email' => $request->customer_external_id], // 假設 external_id 是 email
                ['name' => 'Customer from ' . $request->source_channel, 'password' => \Illuminate\Support\Str::random(10), 'role' => 'customer']
            );
            $customer_id = $customer->id;
        }

        if (!$customer_id) {
            return response()->json(['message' => 'Customer ID is required.'], 400);
        }

        $ticket = Ticket::create([
            'customer_id' => $customer_id,
            'subject' => $request->subject,
            'status' => 'pending', // 新工單預設為待處理
            'priority' => $request->priority ?? 'normal',
            'source_channel' => $request->source_channel ?? 'web',
        ]);

        // 創建第一條回覆 (即客戶的原始訊息)
        $ticket->replies()->create([
            'user_id' => null, // 初始訊息來自客戶，無對應內部用戶
            'content' => $request->description,
            'is_ai_reply' => false,
            'reply_from_source' => $request->source_channel ?? 'web',
        ]);

        // 可以觸發一個 Job 來通知 AI 服務處理這個新工單
        // ProcessNewTicketForAI::dispatch($ticket);

        return response()->json($ticket, 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Ticket  $ticket
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Ticket $ticket)
    {
        // 客戶只能查看自己的工單
        if (Auth::user()->role === 'customer' && Auth::id() !== $ticket->customer_id) {
            return response()->json(['message' => 'Unauthorized to view this ticket.'], 403);
        }

        $ticket->load(['customer', 'assignee', 'replies' => function($query) {
            $query->orderBy('created_at', 'asc')->with('user');
        }]);
        return response()->json($ticket);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \App\Http\Requests\Ticket\UpdateTicketRequest  $request
     * @param  \App\Models\Ticket  $ticket
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(UpdateTicketRequest $request, Ticket $ticket)
    {
        // 只有客服和管理員可以更新工單狀態或指派對象
        if (!in_array(Auth::user()->role, ['agent', 'admin'])) {
            return response()->json(['message' => 'Unauthorized to update tickets.'], 403);
        }

        $ticket->update($request->validated());

        return response()->json($ticket);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Ticket  $ticket
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Ticket $ticket)
    {
        // 只有管理員可以刪除
        if (Auth::user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized to delete tickets.'], 403);
        }

        $ticket->delete();

        return response()->json(['message' => 'Ticket deleted successfully.'], 204);
    }

    /**
     * Add a reply to a ticket.
     *
     * @param  \App\Http\Requests\Ticket\ReplyTicketRequest  $request
     * @param  \App\Models\Ticket  $ticket
     * @return \Illuminate\Http\JsonResponse
     */
    public function addReply(ReplyTicketRequest $request, Ticket $ticket)
    {
        // 只有授權用戶（客服、管理員或該工單的客戶）可以回覆
        if (!in_array(Auth::user()->role, ['agent', 'admin']) && Auth::id() !== $ticket->customer_id) {
            return response()->json(['message' => 'Unauthorized to reply to this ticket.'], 403);
        }

        $reply = $ticket->replies()->create([
            'user_id' => Auth::id(), // 回覆用戶
            'content' => $request->content,
            'is_ai_reply' => false,
            'reply_from_source' => 'system_panel', // 假設來自客服面板
        ]);

        // 更新工單狀態為已回覆
        if ($ticket->status !== 'resolved' && $ticket->status !== 'closed') {
            $ticket->update(['status' => 'replied']);
        }

        // 廣播回覆事件
        broadcast(new MessageReplied($ticket, $reply))->toOthers();

        // 如果回覆是來自客服，可以發送郵件通知客戶
        if (Auth::user()->role !== 'customer') {
            Mail::to($ticket->customer->email)->send(new CustomerReplyMail($ticket, $reply));
        }

        return response()->json($reply, 201);
    }
}
