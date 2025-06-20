<?php

namespace App\Http\Requests\Ticket;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;

class UpdateTicketRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Only agents and admins can update tickets
        return Auth::check() && in_array(Auth::user()->role, ['agent', 'admin']);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'status' => 'nullable|string|in:pending,assigned,in_progress,replied,resolved,closed',
            'priority' => 'nullable|string|in:low,normal,high,urgent',
            'assigned_to' => 'nullable|exists:users,id', // 只能指派給現有用戶
            'sentiment' => 'nullable|string|in:positive,negative,neutral',
            'intent' => 'nullable|string|max:255',
        ];
    }
}
