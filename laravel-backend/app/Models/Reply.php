<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Reply extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'ticket_id',
        'user_id', // 回覆者的 ID (可以是客戶、客服或 null 代表 AI/系統)
        'content',
        'is_ai_reply', // 標識是否為 AI 自動回覆
        'reply_from_source', // 回覆是來自哪個系統 (agent, system_ai, customer_web_chat, customer_email, etc.)
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'is_ai_reply' => 'boolean',
    ];

    /**
     * Get the ticket that the reply belongs to.
     */
    public function ticket(): BelongsTo
    {
        return $this->belongsTo(Ticket::class);
    }

    /**
     * Get the user that made the reply (if any).
     */
    public function user(): BelongsTo
    {
        // user_id 可以為 null (例如 AI 回覆)
        return $this->belongsTo(User::class, 'user_id')->withDefault([
            'name' => 'AI/System', // 提供默認名稱
            'email' => 'system@example.com'
        ]);
    }
}
