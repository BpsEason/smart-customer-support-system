<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ticket extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_identifier',
        'subject',
        'description',
        'status',
        'priority',
        'assigned_to_user_id',
        'category',
    ];

    // 工單可以被指派給一個用戶 (客服)
    public function assignedToUser()
    {
        return $this->belongsTo(User::class, 'assigned_to_user_id');
    }

    // 工單可以有多個回覆
    public function replies()
    {
        return $this->hasMany(TicketReply::class);
    }
}
