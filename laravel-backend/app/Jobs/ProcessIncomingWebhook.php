<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use App\Models\Ticket;
use App\Models\Reply;
use App\Events\MessageReplied;

class ProcessIncomingWebhook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $ticketId;
    protected $messageContent;
    protected $customerId;
    protected $sourceChannel;

    /**
     * Create a new job instance.
     */
    public function __construct(int $ticketId, string $messageContent, int $customerId, string $sourceChannel)
    {
        $this->ticketId = $ticketId;
        $this->messageContent = $messageContent;
        $this->customerId = $customerId;
        $this->sourceChannel = $sourceChannel;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        Log::info("Processing incoming message for Ticket ID: {$this->ticketId}");

        $ticket = Ticket::find($this->ticketId);
        if (!$ticket) {
            Log::error("Ticket with ID {$this->ticketId} not found for webhook processing.");
            return;
        }

        // Add the customer's incoming message as a reply to the ticket
        $customerReply = $ticket->replies()->create([
            'user_id' => null, // Initial message from customer, no internal user
            'content' => $this->messageContent,
            'is_ai_reply' => false,
            'reply_from_source' => $this->sourceChannel,
        ]);

        // Send message to FastAPI AI service for analysis and possible AI reply
        try {
            $aiServiceUrl = env('FASTAPI_AI_SERVICE_URL') . '/ai/process_incoming_message';
            $response = Http::timeout(60)->post($aiServiceUrl, [
                'ticket_id' => $ticket->id,
                'message' => $this->messageContent,
                'customer_id' => $this->customerId, // Pass customer_id for potential personalized responses
            ]);

            if ($response->successful()) {
                $aiResponse = $response->json();
                Log::info('AI Service Response:', $aiResponse);

                // Update ticket with sentiment and intent from AI
                $ticket->update([
                    'sentiment' => $aiResponse['sentiment'] ?? $ticket->sentiment,
                    'intent' => $aiResponse['intent'] ?? $ticket->intent,
                ]);

                // If AI provides a direct reply, add it to the ticket
                if (!empty($aiResponse['ai_reply'])) {
                    $aiReply = $ticket->replies()->create([
                        'user_id' => null, // AI reply, no specific internal user
                        'content' => $aiResponse['ai_reply'],
                        'is_ai_reply' => true,
                        'reply_from_source' => 'ai_service',
                    ]);
                    Log::info("AI replied to Ticket ID {$ticket->id}: {$aiResponse['ai_reply']}");

                    // Broadcast AI reply
                    broadcast(new MessageReplied($ticket, $aiReply))->toOthers();

                    // Update ticket status if AI replied and it was pending/in_progress
                    if (in_array($ticket->status, ['pending', 'in_progress'])) {
                        $ticket->update(['status' => 'replied']);
                    }
                } else {
                    // If no direct AI reply, but needs human attention, update status
                    if ($ticket->status === 'pending') {
                        $ticket->update(['status' => 'in_progress']); // Mark as in progress if no AI reply but AI processed it
                    }
                }

                // Dispatch another job for AI to suggest a human agent or escalate
                // ProcessAiReply::dispatch($ticket->id, $aiResponse); // 如果 ProcessAiReply 有更多複雜邏輯
            } else {
                Log::error('Failed to get response from AI service:', [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                // Fallback: If AI service fails, set ticket status accordingly
                if ($ticket->status === 'pending') {
                    $ticket->update(['status' => 'in_progress', 'priority' => 'high']); // 優先級提高，需人工介入
                }
            }
        } catch (\Exception $e) {
            Log::error('Error communicating with AI service: ' . $e->getMessage());
            // Fallback: If AI service fails, set ticket status accordingly
            if ($ticket->status === 'pending') {
                $ticket->update(['status' => 'in_progress', 'priority' => 'high']); // 優先級提高，需人工介入
            }
        }
    }
}
