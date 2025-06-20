<?php

namespace App\Http\Requests\Ticket;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;

class UpdateTicketRequest extends FormRequest
{
    /**
     * 確定用戶是否有權限發出此請求。
     */
    public function authorize(): bool
    {
        // 只有客服或管理員可以更新工單
        return Auth::check() && (Auth::user()->role === 'agent' || Auth::user()->role === 'admin');
    }

    /**
     * 獲取應用於請求的驗證規則。
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'subject' => 'sometimes|required|string|max:255', // 可以選擇性更新主題
            'description' => 'sometimes|required|string|max:5000', // 可以選擇性更新描述
            'status' => 'sometimes|required|string|in:pending,assigned,in_progress,replied,resolved,closed',
            'priority' => 'sometimes|required|string|in:low,normal,high,urgent',
            'assigned_to' => 'sometimes|nullable|exists:users,id', // 必須是現有的用戶ID，可以為空
            'is_ai_handled' => 'sometimes|boolean',
            'needs_human_attention' => 'sometimes|boolean',
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
            'status.in' => '狀態無效。',
            'priority.in' => '優先級無效。',
            'assigned_to.exists' => '指派的用戶不存在。',
            'is_ai_handled.boolean' => 'AI 處理標誌必須為布林值。',
            'needs_human_attention.boolean' => '人工介入標誌必須為布林值。',
        ];
    }
}