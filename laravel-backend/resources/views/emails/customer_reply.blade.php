<!DOCTYPE html>
<html>
<head>
    <title>工單回覆通知</title>
</head>
<body>
    <h1>您的工單 "{{ $ticket->subject }}" 有新回覆</h1>
    <p>工單編號: #{{ $ticket->id }}</p>
    <p>最後回覆:</p>
    <div style="border: 1px solid #ccc; padding: 10px; margin-bottom: 20px;">
        <p>{{ $reply->content }}</p>
        <small>回覆時間: {{ $reply->created_at->format('Y-m-d H:i:s') }}</small>
        @if ($reply->is_ai_reply)
            <small>(AI 自動回覆)</small>
        @else
            <small>由 {{ $reply->user->name ?? '未知用戶' }} 回覆</small>
        @endif
    </div>
    <p>您可以登入系統查看完整回覆和工單詳情。</p>
    <p><a href="http://localhost/tickets/{{ $ticket->id }}">查看工單詳情</a></p>
    <p>感謝您的耐心等待！</p>
</body>
</html>