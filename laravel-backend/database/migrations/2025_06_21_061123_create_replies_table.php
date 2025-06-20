<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('replies', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ticket_id')->constrained('tickets')->onDelete('cascade');
            $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('set null'); // 回覆者，可以是客服，也可以是 null (AI 或客戶原始訊息)
            $table->text('content');
            $table->boolean('is_ai_reply')->default(false); // 標記是否為 AI 回覆
            $table->string('reply_from_source')->nullable(); // 'system_panel', 'ai_service', 'customer_web'
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('replies');
    }
};
