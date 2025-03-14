<#
The language file name is ChatGPT-Conversation_XXX.psd1
If the manually set name does not have a matching language file, the system language will be automatically detected.
If the system language does not have a matching language file, English will be automatically used.
#>

Function Load-LanguageResource {
    # 首先檢查初始的 resourcePath
    $resourcePath = Join-Path -Path $PSScriptRoot -ChildPath "ChatGPT-Conversation_$languageCode.psd1"
    if (-not (Test-Path $resourcePath)) {
        # 如果找不到，嘗試使用系統語系
        $languageCode = try {
            (Get-Culture).Name
        } catch {
            # 如果 Get-Culture 失敗，設置為空，這樣下面的邏輯就會用 default
            ""
        }
        # 更新 resourcePath
        $resourcePath = Join-Path -Path $PSScriptRoot -ChildPath "ChatGPT-Conversation_$languageCode.psd1"
    }
    if (Test-Path $resourcePath) {
        return Import-PowerShellDataFile -Path $resourcePath
    } else {
        Write-Host "Language resource not found, using default." -ForegroundColor Yellow
        return @{
            WelcomeMessage = "`nType 'eof' to switch to paragraph input mode,`nType 'read' to Read a plain text file,`nType 'image' to use DALL-E to create an image,`nType 'upload' to upload an image for Vision,`nType 'save' to save the chat history or 'load' to load the chat history.`nType 'usage' to check incurred fees.`nType 'setting' to set model and temperature.`nType 'exit' to quit or 'reset' to start a new chat."
            Input_cannot_be_blank_please_re_enter = "Input cannot be blank, please re-enter."
            Please_enter_your_text_And_when_you_are_finished_Type_EOF_on_a_new_line_to_end = "Please enter your text, and when you are finished, type 'EOF' on a new line to end:"
            Please_select_a_model = "Please select a model:"
            Your_choice = "`nYour choice"
            Switched_to_Model = "Switched to Model:"
            Respond_Token_Limit = "Respond Token Limit:"
            Unknown_option_Original_settings_will_be_maintained = "Unknown option, original settings will be maintained."
            Please_select_a_mode_1Steady_2Default_3Creative = "Please select a mode:`n1. Steady`n2. Default`n3. Creative"
            Set_to_Steady_mode = "Set to Steady mode."
            Set_to_Default_mode = "Set to Default mode."
            Set_to_Creative_mode = "Set to Creative mode."
            Settings_completed_Returning_to_the_main_menu = "Settings completed, returning to the main menu."
            Please_drag_the_text_file_you_want_to_read_into_the_window = "Please drag the text file you want to read into the window:"
            The_content_of_the_file_read_is = "The content of the file read is:"
            File_read_successfully = "`nFile read successfully"
            File_read_error = "`nFile read error"
            Error = "Error: "
            Reminder_to_get_bear_token = "Reminder: Use a browser to go to https://platform.openai.com/usage and copy the request header 'Authorization' used in GET 'credit_grants'"
            Please_enter_the_new_Web_Token_including_Bearer = "Please enter the new Web Token (including Bearer)"
            The_new_Web_Token_has_been_saved_to_the_environment_variable_OPENAI_WEB_TOKEN = "The new Web Token has been saved to the environment variable 'OPENAI_WEB_TOKEN'"
            Error_type = "Error type: "
            Error_message = "Error message: "
            Remaining_balance = "`nRemaining balance  :"
            Total_usage_cost = "`nTotal usage cost:"
            Please_select_an_option_1Optimize_prompts_and_generate_image_2Generate_image_with_original_prompts_3Settings = "`nPlease select an option:`n1. Optimize prompts and generate image`n2. Generate image with original prompts`n3. Settings"
            Enter_settings_mode = "Enter settings mode:"
            Please_select_a_model_1DALL_E_2_2DALL_E_3 = "Please select a model:`n1. DALL·E 2`n2. DALL·E 3"
            Switched_model = "Switched model: "
            Please_select_a_size = "Please select a size:`n1. 256x256 (DALL·E 2 Only)`n2. 512x512 (DALL·E 2 Only)`n3. 1024x1024`n4. 1024x1792 (Only DALL·E 3)`n5. 1792x1024 (DALL·E 3 Only)"
            Size_set_to = "Size set to: "
            Please_select_a_quality = "Please select a quality:`n1. standard`n2. hd (DALL·E 3 only)"
            Quality_set_to = "Quality set to: "
            Settings_completed = "Settings completed."
            Unknown_choice_Please_re_enter = "Unknown choice, please re-enter."
            An_error_occurred_while_calculating_Token = "⚠️ An error occurred while calculating Token: "
            Processing = "...Processing ("
            Sent_this_time_using = "sent this time using ["
            Tokens = "tokens])..."
            Warning_There_are = "⚠️ Warning: There are "
            Tokens_left_until_the_token_limit_of = "tokens left until the token limit of "
            Is_reached = " is reached."
            An_error_occurred_while_calling_ChatGPT = "⚠️ An error occurred while calling ChatGPT:"
            Respond_this_time_using = "Respond this time using["
            Please_enter_a_prompt_for_creating_an_image_Enter_exit_to_leave_the_image_creation_Function = "`nPlease enter a prompt for creating an image (enter 'exit' to leave the image creation Function)."
            Current_settings = "Current settings:"
            Optimizing = "Optimizing..."
            Optimized_prompt = "`nOptimized prompt: "
            Generated_image_URL = "`nGenerated image URL:"
            Image_generation_API_call_failed = "⚠️ Image generation API call failed:"
            An_error_occurred_while_saving_the_conversation_history_file = "⚠️ An error occurred while saving the conversation history file:"
            Conversation_history_has_been_saved_to = "Conversation history has been saved to"
            An_error_occurred_while_reading_the_conversation_history_file = "⚠️ An error occurred while reading the conversation history file:"
            Conversation_history_has_been_loaded = "Conversation history has been loaded"
            Gpt_history_log_file_not_found = "gpt_history.log file not found"
            No_image_found_at_the_specified_path_Please_verify_if_the_path_is_correct = "No image found at the specified path, please verify if the path is correct."
            Image_reading_failed_Please_confirm_whether_the_path_or_file_is_correct = "⚠️ Image reading failed, please confirm whether the path or file is correct:"
            Enter_the_path_to_upload_the_image = "Enter the path to upload the image"
            Image_uploading = "Image uploading..."
            Token_calculation_Python_script_call_failed = "⚠️ Token calculation (Python script) call failed:"
            Unable_to_recognize_the_format_of_the_AI_response = "⚠️ Unable to recognize the format of the AI ​​response!"
            An_error_occurred_while_calculating_the_AI_response_token = "⚠️ An error occurred while calculating the AI ​​response token:"
            No_API_Key_is_set_Please_set_the_OPENAI_API_KEY_environment_variable = "No API Key is set. Please set the OPENAI_API_KEY environment variable."
        }
    }
}