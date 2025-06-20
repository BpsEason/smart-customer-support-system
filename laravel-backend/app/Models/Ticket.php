<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Ticket extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'customer_id',
        'subject',
        'description', // 原始描述可以作為第一個回覆的內容
        'status',      // pending, assigned, in_progress, replied, resolved, closed
        'priority',    // low, normal, high, urgent
        'assigned_to', // ID of the agent/admin assigned
        'source_channel', // e.g., 'web', 'email', 'line_webhook'
        'sentiment',   // positive, negative, neutral (from AI analysis)
        'intent',      // e.g., 'password_reset', 'product_inquiry' (from AI analysis)
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        // 'created_at' => 'datetime', // Already cast by default
        // 'updated_at' => 'datetime', // Already cast by default
    ];

    /**
     * Get the customer that owns the ticket.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Get the agent/admin assigned to the ticket.
     */
    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    /**
     * Get the replies for the ticket.
     */
    public function replies(): HasMany
    {
        return $this->hasMany(Reply::class);
    }
}
