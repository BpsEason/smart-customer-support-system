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
