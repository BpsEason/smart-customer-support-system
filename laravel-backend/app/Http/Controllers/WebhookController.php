<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Jobs\ProcessIncomingWebhook;
use App\Models\User;
use App\Models\Ticket;

class WebhookController extends Controller
{
    /**
     * Handle incoming messages from external systems (e.g., web chat, email forms, Line Bot).
     * This endpoint should be publicly accessible but may require a secret token for verification.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function handleIncoming(Request $request)
    {
        // Log the received webhook data for debugging
        Log::info('Received incoming webhook:', $request->all());

        // Basic validation; adjust based on your actual external system's payload
        $request->validate([
            'message' => 'required|string|max:5000',
            'customer_identifier' => 'required|string|max:255', // e.g., customer's email or external ID
            'source_channel' => 'required|string|in:web_chat,email,line_webhook,other', // Message source
            'subject' => 'nullable|string|max:255', // Subject for new tickets
            // Add more validation, e.g., signature verification for security
        ]);

        // Find or create a customer based on the identifier
        // Assuming customer_identifier is email for simplicity
        $customer = User::firstOrCreate(
            ['email' => $request->input('customer_identifier')],
            ['name' => 'External Customer', 'password' => \Illuminate\Support\Str::random(10), 'role' => 'customer'] // Generate random password
        );

        // Find an existing open ticket for this customer, or create a new one
        $ticket = Ticket::where('customer_id', $customer->id)
                        ->whereIn('status', ['pending', 'in_progress', 'replied']) // Consider only open/active tickets
                        ->orderBy('updated_at', 'desc')
                        ->first();

        if (!$ticket) {
            // Create a new ticket if no open one exists
            $ticket = Ticket::create([
                'customer_id' => $customer->id,
                'subject' => $request->input('subject', 'New Inquiry from ' . $request->input('source_channel')),
                'status' => 'pending',
                'priority' => 'normal',
                'source_channel' => $request->input('source_channel'),
            ]);
        }

        // Dispatch the message to a queue for asynchronous processing
        ProcessIncomingWebhook::dispatch(
            $ticket->id,
            $request->input('message'),
            $customer->id,
            $request->input('source_channel')
        );

        return response()->json(['status' => 'Message received and queued for processing.'], 202);
    }
}
