@{
    WelcomeMessage = "`n輸入 'eof'     切換到可換行連續輸入模式。`n輸入 'read'    上傳純文字檔案。`n輸入 'image'   使用 DALL-E 生成圖片。`n輸入 'upload'  上傳圖片讓 AI 感知。`n輸入 'save'    將當前對話儲存；輸入 'load' 載入上次對話。`n輸入 'usage'   檢查使用的費用。`n輸入 'setting' 切換使用的對話模型與溫度。`n輸入 'exit'    跳出；輸入 'reset' 將對話歷史清除。"
    Input_cannot_be_blank_please_re_enter = "輸入不能為空白，請重新輸入。"
    Please_enter_your_text_And_when_you_are_finished_Type_EOF_on_a_new_line_to_end = "請輸入你的文章，當完成輸入請在新的一行輸入 'EOF' 來結束："
    Please_select_a_model = "請選擇一個模型："
    Your_choice = "`n你的選擇"
    Switched_to_Model = "已切換至模型："
    Respond_Token_Limit = "回應 Token 上限："
    Unknown_option_Original_settings_will_be_maintained = "未知的選項，將維持原設定。"
    Please_select_a_mode_1Steady_2Default_3Creative = "請選擇一個模式：`n1. 穩重`n2. 預設`n3. 創意"
    Set_to_Steady_mode = "已設定為穩重模式。"
    Set_to_Default_mode = "已設定為預設模式。"
    Set_to_Creative_mode = "已設定為創意模式。"
    Settings_completed_Returning_to_the_main_menu = "設定完成，返回主選單。"
    Please_drag_the_text_file_you_want_to_read_into_the_window = "請將要讀取的純文字檔案拖到視窗："
    The_content_of_the_file_read_is = "讀取的文件內容為："
    File_read_successfully = "`n檔案讀取成功"
    File_read_error = "`n讀取錯誤"
    Error = "Error： "
    Reminder_to_get_bear_token = "提醒：使用瀏覽器前往 https://platform.openai.com/usage 並複製 GET 'credit_grants' 所使用的請求標頭 'Authorization'"
    Please_enter_the_new_Web_Token_including_Bearer = "Please enter the new Web Token (including Bearer)"
    The_new_Web_Token_has_been_saved_to_the_environment_variable_OPENAI_WEB_TOKEN = "新的 Web Token 已儲存到環境變數 'OPENAI_WEB_TOKEN'。"
    Error_type = "錯誤類型： "
    Error_message = "錯誤訊息： "
    Remaining_balance = "`n剩餘費用  ："
    Total_usage_cost = "`n共使用費用："
    Please_select_an_option_1Optimize_prompts_and_generate_image_2Generate_image_with_original_prompts_3Settings = "`n請選擇一個選項：`n1. 最佳化提示詞並生成圖片`n2. 原始提示詞生成圖片`n3. 設定"
    Enter_settings_mode = "進入設定模式："
    Please_select_a_model_1DALL_E_2_2DALL_E_3 = "請選擇模型：`n1. DALL·E 2`n2. DALL·E 3"
    Switched_model = "已切換至模型："
    Please_select_a_size = "請選擇尺寸：`n1. 256x256 (DALL·E 2 Only)`n2. 512x512 (DALL·E 2 Only)`n3. 1024x1024`n4. 1024x1792 (DALL·E 3 Only)`n5. 1792x1024 (DALL·E 3 Only)"
    Size_set_to = "已設定尺寸為： "
    Please_select_a_quality = "請選擇品質：`n1. standard`n2. hd (DALL·E 3 Only)"
    Quality_set_to = "已設定品質為： "
    Settings_completed = "設定完成。"
    Unknown_choice_Please_re_enter = "未知的選擇，請重新輸入。"
    An_error_occurred_while_calculating_Token = "⚠️ 計算 Token 時發生錯誤： "
    Processing = "...處理中 ("
    Sent_this_time_using = "這次送出使用了【"
    Tokens = "個 tokens】)...`n"
    Warning_There_are = "⚠️ 警告：距離 context token 上限 "
    Tokens_left_until_the_token_limit_of = "還剩下"
    Is_reached = " 個"
    An_error_occurred_while_calling_ChatGPT = "⚠️ 呼叫 ChatGPT 時發生錯誤："
    Respond_this_time_using = "這次回應使用了【"
    Please_enter_a_prompt_for_creating_an_image_Enter_exit_to_leave_the_image_creation_Function = "`n請輸入創建圖片的提示詞（輸入 'exit' 離開創建圖片功能）"
    Current_settings = "當前設定："
    Optimizing = "最佳化中..."
    Optimized_prompt = "`n最佳化後的提示詞： "
    Generated_image_URL = "`n生成的圖片 URL： "
    Image_generation_API_call_failed = "⚠️ 圖片生成 API 呼叫失敗："
    An_error_occurred_while_saving_the_conversation_history_file = "⚠️ 儲存對話歷史檔案發生錯誤："
    Conversation_history_has_been_saved_to = "對話歷史已保存到 "
    An_error_occurred_while_reading_the_conversation_history_file = "⚠️ 讀取對話歷史檔案發生錯誤："
    Conversation_history_has_been_loaded = "對話歷史已載入"
    Gpt_history_log_file_not_found = "找不到 gpt_history.log 檔案"
    No_image_found_at_the_specified_path_Please_verify_if_the_path_is_correct = "⚠️ 找不到該路徑的圖片，請確認路徑是否正確。"
    Image_reading_failed_Please_confirm_whether_the_path_or_file_is_correct = "⚠️ 圖片讀取失敗，請確認路徑或檔案是否正確："
    Enter_the_path_to_upload_the_image = "請輸入要上傳圖片的路徑"
    Image_uploading = "圖片上傳中..."
    Token_calculation_Python_script_call_failed = "⚠️ Token 計算 (Python腳本) 呼叫失敗："
    Unable_to_recognize_the_format_of_the_AI_response = "⚠️ 無法識別 AI 回應的格式！"
    An_error_occurred_while_calculating_the_AI_response_token = "⚠️ 計算 AI 回應 token 時發生錯誤："
    No_API_Key_is_set_Please_set_the_OPENAI_API_KEY_environment_variable = "沒有設定 API Key，請設定 OPENAI_API_KEY 環境變數"
}