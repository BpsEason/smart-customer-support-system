<!DOCTYPE html>
<html>
<head>
    <title>Support Ticket Reply</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { width: 80%; margin: 20px auto; border: 1px solid #ddd; padding: 20px; }
        .header { background: #f0f0f0; padding: 10px; text-align: center; }
        .content { margin-top: 20px; }
        .footer { margin-top: 30px; font-size: 0.9em; color: #777; text-align: center; }
        .reply-box { border-left: 3px solid #007bff; padding-left: 15px; margin-top: 15px; background-color: #f9f9f9; }
        .ticket-info { margin-bottom: 20px; border-bottom: 1px solid #eee; padding-bottom: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>Support Ticket Update</h2>
        </div>
        <div class="content">
            <p>Dear {{ $ticket->customer->name ?? 'Customer' }},</p>
            <p>Your support ticket #{{ $ticket->id }} (Subject: {{ $ticket->subject }}) has received a new reply.</p>

            <div class="ticket-info">
                <h3>Ticket Details:</h3>
                <p><strong>Status:</strong> {{ ucfirst($ticket->status) }}</p>
                <p><strong>Priority:</strong> {{ ucfirst($ticket->priority) }}</p>
            </div>

            <h3>New Reply:</h3>
            <div class="reply-box">
                <p><strong>From:</strong> {{ $reply->user->name ?? 'AI/System' }} ({{ $reply->reply_from_source }})</p>
                <p><strong>Date:</strong> {{ $reply->created_at->format('Y-m-d H:i:s') }}</p>
                <p>{!! nl2br(e($reply->content)) !!}</p>
            </div>

            <p>You can view the full ticket history by logging into your account or replying to this email.</p>
            <p>Thank you for your patience.</p>
        </div>
        <div class="footer">
            <p>Best regards,</p>
            <p>The {{ config('app.name') }} Team</p>
        </div>
    </div>
</body>
</html>
