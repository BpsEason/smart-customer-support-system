<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\WebhookController;
use App\Http\Controllers\TicketController;
use App\Http\Controllers\UserController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Webhook 接收，處理來自外部系統的訊息
// !! 安全性提醒: 考慮為此端點增加 IP 白名單、請求簽名驗證或 API Key 等安全措施。
Route::post('/webhook/incoming', [WebhookController::class, 'handleIncomingMessage']);

// 用戶認證
Route::post('/register', [UserController::class, 'register']);
Route::post('/login', [UserController::class, 'login']);

// 需要認證的路由 (使用 Laravel Sanctum 示例)
Route::middleware('auth:sanctum')->group(function () {
    // 用戶管理
    Route::apiResource('users', UserController::class);

    // 票務系統
    Route::apiResource('tickets', TicketController::class);
    Route::post('/tickets/{ticket}/reply', [TicketController::class, 'addReply']);

    // 儀表板數據
    Route::get('/dashboard/stats', [TicketController::class, 'getDashboardStats']);

    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});
