<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;
use App\Models\Ticket;
use App\Models\Reply;

class CustomerReplyMail extends Mailable
{
    use Queueable, SerializesModels;

    public $ticket;
    public $reply;

    /**
     * 創建一個新的訊息實例。
     */
    public function __construct(Ticket $ticket, Reply $reply)
    {
        $this->ticket = $ticket;
        $this->reply = $reply;
    }

    /**
     * 獲取訊息的信封。
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: '您的工單 ' . $this->ticket->subject . ' 有新回覆',
        );
    }

    /**
     * 獲取訊息的內容定義。
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.customer_reply', // 會使用 resources/views/emails/customer_reply.blade.php
            with: [
                'ticket' => $this->ticket,
                'reply' => $this->reply,
            ],
        );
    }

    /**
     * 獲取訊息的附件。
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}