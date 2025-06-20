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
        Schema::create('tickets', function (Blueprint $table) {
            $table->id();
            $table->string('subject'); // 工單主題
            $table->text('description'); // 工單描述或初始訊息內容
            $table->string('status')->default('pending'); // 狀態：pending, assigned, in_progress, replied, resolved, closed
            $table->string('priority')->default('normal'); // 優先級：low, normal, high, urgent
            $table->string('source_channel')->nullable(); // 訊息來源頻道 (e.g., web_chat, email, line_webhook)
            $table->boolean('is_ai_handled')->default(false); // 是否主要由 AI 處理
            $table->boolean('needs_human_attention')->default(false); // 是否需要人工介入

            // 關聯到用戶表，作為客戶
            $table->foreignId('customer_id')->constrained('users')->onDelete('cascade');
            // 關聯到用戶表，作為被指派的客服 (可為空，表示未指派)
            $table->foreignId('assigned_to')->nullable()->constrained('users')->onDelete('set null');

            $table->timestamps(); // created_at 和 updated_at
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tickets');
    }
};