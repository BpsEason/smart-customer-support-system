<?php

namespace App\Http\Requests\Ticket;

use Illuminate\Foundation\Http\FormRequest;

class CreateTicketRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Allow anyone to create a ticket (even unauthenticated, if customer_external_id is provided)
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'subject' => 'required|string|max:255',
            'description' => 'required|string|max:5000',
            'priority' => 'nullable|string|in:low,normal,high,urgent',
            'source_channel' => 'required|string|in:web,email,phone,webhook,api', // 來源渠道
            'customer_external_id' => 'required_without:customer_id|string|max:255', // 外部客戶標識 (email, phone, etc.)
            'customer_id' => 'nullable|exists:users,id', // 內部客戶 ID (如果已登入)
        ];
    }
}
