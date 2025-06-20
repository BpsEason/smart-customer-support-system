<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    /**
     * 確定用戶是否有權限發出此請求。
     */
    public function authorize(): bool
    {
        // 允許所有用戶訪問註冊功能，根據您的應用邏輯調整
        return true;
    }

    /**
     * 獲取應用於請求的驗證規則。
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users', // 確保 email 在 users 表中唯一
            'password' => 'required|string|min:8|confirmed', // 密碼至少8位，且需要 password_confirmation 字段匹配
            'role' => 'nullable|string|in:customer,agent,admin', // 允許指定角色，默認為 'customer'
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
            'name.required' => '名稱是必填項。',
            'email.required' => '電子郵件是必填項。',
            'email.email' => '電子郵件格式不正確。',
            'email.unique' => '此電子郵件已被註冊。',
            'password.required' => '密碼是必填項。',
            'password.min' => '密碼至少需要8個字符。',
            'password.confirmed' => '密碼確認不匹配。',
            'role.in' => '角色無效。',
        ];
    }
}