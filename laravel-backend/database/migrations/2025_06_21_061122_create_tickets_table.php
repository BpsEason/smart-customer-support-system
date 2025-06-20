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
            $table->foreignId('customer_id')->constrained('users')->onDelete('cascade');
            $table->string('subject');
            $table->string('status')->default('pending'); // pending, assigned, in_progress, replied, resolved, closed
            $table->string('priority')->default('normal'); // low, normal, high, urgent
            $table->foreignId('assigned_to')->nullable()->constrained('users')->onDelete('set null'); // 客服或管理員
            $table->string('source_channel')->default('web'); // web, email, line_webhook, other
            $table->string('sentiment')->nullable(); // positive, negative, neutral
            $table->string('intent')->nullable(); // e.g., 'password_reset', 'product_inquiry'
            $table->timestamps();
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
