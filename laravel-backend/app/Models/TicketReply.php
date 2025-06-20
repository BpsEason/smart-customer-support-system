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
