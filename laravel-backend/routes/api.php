<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\TicketController;
use App\Http\Controllers\WebhookController;

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

// Public routes
Route::post('/register', [AuthController::class, 'register'])->name('register');
Route::post('/login', [AuthController::class, 'login'])->name('login');

// Webhook for incoming messages (e.g., from external chat platforms, email parsers)
// This endpoint should be publicly accessible but secured via a shared secret or IP whitelist
Route::post('/webhook/incoming', [WebhookController::class, 'handleIncoming'])->name('webhook.incoming');

// Authenticated routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
    Route::get('/user', function (Request $request) {
        return $request->user();
    })->name('user.profile');

    // Ticket Management Routes
    Route::apiResource('tickets', TicketController::class); // index, store, show, update, destroy
    Route::post('/tickets/{ticket}/reply', [TicketController::class, 'addReply'])->name('tickets.reply');
    // You might add more specific routes here as needed, e.g., for assigning tickets, changing priority etc.
});
