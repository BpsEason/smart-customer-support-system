<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use App\Models\Ticket;
use App\Models\Reply; // 可選，如果想廣播整個回覆對象

class MessageReplied implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $ticket;
    public $replyContent; // 可選，直接廣播回覆內容
    public $reply; // 可選，廣播完整的 Reply 模型

    /**
     * 創建一個新的事件實例。
     */
    public function __construct(Ticket $ticket, string $replyContent = null, Reply $reply = null)
    {
        $this->ticket = $ticket;
        $this->replyContent = $replyContent;
        $this->reply = $reply;
    }

    /**
     * 獲取事件應廣播的頻道。
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        // 可以廣播到特定工單的私人頻道，只有該工單的相關用戶能收到
        return [
            new PrivateChannel('tickets.' . $this->ticket->id),
            // 也可以廣播到一個公共頻道，供所有客服儀表板更新
            new Channel('tickets.public'),
        ];
    }

    /**
     * 廣播數據的名稱。
     *
     * @return string
     */
    public function broadcastAs(): string
    {
        return 'ticket.replied';
    }

    /**
     * 獲取廣播的數據。
     *
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        // 可以選擇廣播哪些數據
        return [
            'ticket_id' => $this->ticket->id,
            'status' => $this->ticket->status,
            'last_reply_content' => $this->replyContent,
            'reply' => $this->reply ? $this->reply->load('user') : null, // 載入回覆及發送者
            'updated_at' => $this->ticket->updated_at->toDateTimeString(),
        ];
    }
}