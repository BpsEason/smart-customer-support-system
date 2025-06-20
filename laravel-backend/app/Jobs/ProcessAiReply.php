<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use App\Models\Ticket;
use App\Models\Reply;
use App\Models\User;
use App\Mail\CustomerReplyMail;
use Illuminate\Support\Facades\Mail;
use App\Events\MessageReplied;

class ProcessAiReply implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $ticketId;
    protected $aiResponse;

    /**
     * Create a new job instance.
     */
    public function __construct(int $ticketId, array $aiResponse)
    {
        $this->ticketId = $ticketId;
        $this->aiResponse = $aiResponse;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        $ticket = Ticket::find($this->ticketId);

        if (!$ticket) {
            Log::error("Ticket with ID {$this->ticketId} not found for AI reply processing.");
            return;
        }

        // Update ticket with sentiment and intent from AI analysis
        $ticket->update([
            'sentiment' => $this->aiResponse['sentiment'] ?? $ticket->sentiment,
            'intent' => $this->aiResponse['intent'] ?? $ticket->intent,
            'status' => $this->aiResponse['suggested_status'] ?? $ticket->status, // AI 建議的狀態
            'assigned_to' => $this->aiResponse['suggested_agent_id'] ?? $ticket->assigned_to, // AI 建議指派對象
        ]);

        // If AI provides a direct reply, add it to the ticket
        if (!empty($this->aiResponse['ai_reply'])) {
            $aiReply = $ticket->replies()->create([
                'user_id' => null, // AI reply, no specific internal user
                'content' => $this->aiResponse['ai_reply'],
                'is_ai_reply' => true,
                'reply_from_source' => 'ai_service',
            ]);
            Log::info("AI replied to Ticket ID {$ticket->id}: {$this->aiResponse['ai_reply']}");

            // Broadcast AI reply
            broadcast(new MessageReplied($ticket, $aiReply))->toOthers();

            // Send email notification to customer if AI replied and customer's email is available
            if ($ticket->customer && $ticket->customer->email) {
                Mail::to($ticket->customer->email)->send(new CustomerReplyMail($ticket, $aiReply));
            }

            // Update ticket status if AI replied and it was pending/in_progress
            if (in_array($ticket->status, ['pending', 'in_progress'])) {
                $ticket->update(['status' => 'replied']);
            }
        } else {
            // If no direct AI reply, but needs human attention, ensure status reflects that
            if ($ticket->status === 'pending') {
                $ticket->update(['status' => 'in_progress']); // Mark as in progress if no AI reply but AI processed it
            }
        }

        Log::info("AI reply processing for Ticket ID {$ticket->id} completed.");
    }
}
