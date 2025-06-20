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
            $table->foreignId('ticket_id')->constrained('tickets')->onDelete('cascade'); // 關聯到哪個工單
            $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('set null'); // 回覆者 (可以是客戶、客服或空，若為 AI 回覆)
            $table->text('content'); // 回覆內容
            $table->boolean('is_ai_reply')->default(false); // 是否為 AI 自動回覆
            $table->string('reply_from_source')->nullable(); // 回覆來源 (e.g., system_auto, agent_web, customer_email)

            $table->timestamps(); // created_at 和 updated_at
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