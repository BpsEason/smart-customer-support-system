<?php

namespace App\Http\Requests\Ticket;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;

class CreateTicketRequest extends FormRequest
{
    /**
     * 確定用戶是否有權限發出此請求。
     */
    public function authorize(): bool
    {
        // 只有已登入的客戶才能創建工單
        // 如果您的系統允許未登入用戶創建工單，請將此處改為 true
        return Auth::check() && Auth::user()->role === 'customer';
    }

    /**
     * 獲取應用於請求的驗證規則。
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'subject' => 'required|string|max:255',
            'description' => 'required|string|max:5000',
            'priority' => 'nullable|string|in:low,normal,high,urgent', // 允許客戶指定優先級，但後端可以覆蓋
            'source_channel' => 'nullable|string|in:web_chat,email,phone,other', // 來源頻道
            // customer_id 不需要，因為 Auth::user()->id 會自動獲取
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
            'subject.required' => '工單主題是必填項。',
            'subject.max' => '工單主題不能超過255個字符。',
            'description.required' => '工單描述是必填項。',
            'description.max' => '工單描述不能超過5000個字符。',
            'priority.in' => '優先級無效。',
            'source_channel.in' => '來源頻道無效。',
        ];
    }
}