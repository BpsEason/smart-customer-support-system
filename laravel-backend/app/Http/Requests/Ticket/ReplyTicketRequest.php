<?php

namespace App\Http\Requests\Ticket;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use App\Models\Ticket;

class ReplyTicketRequest extends FormRequest
{
    /**
     * 確定用戶是否有權限發出此請求。
     */
    public function authorize(): bool
    {
        if (!Auth::check()) {
            return false;
        }

        $ticket = $this->route('ticket'); // 獲取路由參數中的 Ticket 實例

        // 允許客服或管理員回覆任何工單
        if (Auth::user()->role === 'agent' || Auth::user()->role === 'admin') {
            return true;
        }

        // 允許工單的客戶回覆自己的工單
        if (Auth::user()->role === 'customer' && $ticket && $ticket->customer_id === Auth::id()) {
            return true;
        }

        return false;
    }

    /**
     * 獲取應用於請求的驗證規則。
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'content' => 'required|string|max:5000', // 回覆內容
            'reply_from_source' => 'nullable|string|in:agent_web,customer_web,customer_email,system_auto', // 回覆來源
            // is_ai_reply 通常由後端邏輯判斷，不需要用戶提交
        ];
    }

    /**
     * 獲取驗證錯誤訊息。
     *
     * @return array
     */
    public function messages(): array
    {
        return [
            'content.required' => '回覆內容是必填項。',
            'content.max' => '回覆內容不能超過5000個字符。',
            'reply_from_source.in' => '回覆來源無效。',
        ];
    }
}