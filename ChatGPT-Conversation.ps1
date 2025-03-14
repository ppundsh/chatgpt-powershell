. "$PSScriptRoot\ChatGPT-Conversation-MainFunctions.ps1"   # 載入主要函式
. "$PSScriptRoot\ChatGPT-Conversation-LangFunction.ps1"    # 載入語言函式，預設語言為英文

<#
This script will let you have a conversation with ChatGPT.
It shows how to keep a history of all previous messages and feed them into the REST API in order to have an ongoing conversation.
#>

<#
System message.
You can use this to give the AI instructions on what to do, how to act or how to respond to future prompts.
Default value for ChatGPT = "You are a helpful assistant."
#>
$AiSystemMessage = "You are a helpful assistant,You answered in traditional Chinese"

#languageCode = "zh-TW"  # Manually set the script language
$model = "gpt-4o"        # Initialize default model
$temperature = 0.7       # Lower is more coherent and conservative, higher is more creative and diverse.

# Initialize default image settings
$currentModel = "dall-e-3"
$currentSize = "1024x1024"
$currentQuality = "standard"
$DalleOptimizationMessage = "Optimize the following prompt words into a more explicit expression, strong style, and delicate and rich details, with the meticulousness of a master's work. The reply content should be delivered directly to Dell-e-3. Just reply to the prompt: "

# 定義可選的模型,https://platform.openai.com/docs/models
# respondTokenLimit: Max amount of tokens the AI will respond with
$models = [ordered]@{
    "1" = @{Model = "gpt-4o"; respondTokenLimit = 10000; contextTokenLimit = 128000; modelType = "chat"}
    "2" = @{Model = "gpt-4.5-preview"; respondTokenLimit = 10000; contextTokenLimit = 128000 ;modelType = "chat"}
    "3" = @{Model = "o3-mini"; respondTokenLimit = 80000; contextTokenLimit = 200000; modelType = "reasoning"}
    "4" = @{Model = "o1"; respondTokenLimit = 80000; contextTokenLimit = 200000; modelType = "reasoning"}
    "5" = @{Model = "gpt-4o-search-preview"; respondTokenLimit = 5000; contextTokenLimit = 128000; modelType = "reasoning"}
}
#model                  Context window	Max output tokens
#gpt-4o-2024-08-06      128,000 tokens  16,384 tokens
#gpt-4.5-preview        128,000 tokens  16,384 tokens
#gpt-o3-min             200,000 tokens  100,000 tokens
#gpt-o1                 200,000 tokens  100,000 tokens
#gpt-4o-search-preview  128,000 tokens  16,384 tokens

# 定義 Dall-e 模型與可用選項,https://platform.openai.com/docs/guides/image-generation
$modelOptions = [ordered]@{
    "1" = "dall-e-2"
    "2" = "dall-e-3"
}
$sizeOptions = [ordered]@{
    "1" = "256x256"
    "2" = "512x512"
    "3" = "1024x1024"
    "4" = "1024x1792"
    "5" = "1792x1024"
}
$qualityOptions = [ordered]@{
    "1" = "standard"
    "2" = "hd"
}

# Define API key, WebToken and endpoint
$ApiKey = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY")
$WebToken = [System.Environment]::GetEnvironmentVariable("OPENAI_WEB_TOKEN")
$ApiEndpoint = "https://api.openai.com/v1/chat/completions"

# Initialize
# we use this list to store the system message and will add any user prompts and ai responses as the conversation evolves.
[System.Collections.Generic.List[Hashtable]]$MessageHistory = @()

$Lang = Load-LanguageResource -languageCode $languageCode

# Check apikey
if (-not $ApiKey) {
    Write-Host $Lang.No_API_Key_is_set_Please_set_the_OPENAI_API_KEY_environment_variable -ForegroundColor Red
    exit
}

# Add system message to MessageHistory
Initialize-MessageHistory $AiSystemMessage

# Show startup text
Clear-Host
Write-Host "$('#' * $($($model.Length) + 25))`n# ChatGPT ($model) Powershell #`n$('#' * $($($model.Length) + 25))" -ForegroundColor Yellow
Write-Host $Lang.WelcomeMessage -ForegroundColor Yellow

# Main loop
while ($true) {
    # Capture user input
    $userMessage = Read-Host "`nYou"

    # 檢查送出內容是否為空白
    if ([string]::IsNullOrWhiteSpace($userMessage)) {
        Write-Host $Lang.Input_cannot_be_blank_please_re_enter -ForegroundColor Red
        continue
    }

    if ($userMessage -eq "eof") {
        $userMessage = ""
        Write-Host $Lang.Please_enter_your_text_And_when_you_are_finished_Type_EOF_on_a_new_line_to_end
        do {
            $inputLine = Read-Host
            if ($inputLine -ne "EOF") {
                $userMessage += $inputLine + "`n"
            }
        } while ($inputLine -ne "EOF")
    }
    if ($userMessage -eq "exit") {
        break
    }
    switch ($userMessage) {
        "reset" {
            Initialize-MessageHistory $AiSystemMessage
            Write-Host "Messages reset." -ForegroundColor Yellow
            continue
        }
        "setting" {
            # 顯示可選模型
            Write-Host $Lang.Please_select_a_model
            $models.GetEnumerator() | ForEach-Object {
                Write-Host "$($_.Key). $($_.Value.Model)：	$($Lang.Respond_Token_Limit) $($_.Value.respondTokenLimit)	Type: $($_.Value.modelType)"
            }
            $modelChoice = Read-Host $Lang.Your_choice

            if ($models.Keys -contains $modelChoice) {
                $model = $models[$modelChoice].Model
                $respondTokenLimit = $models[$modelChoice].respondTokenLimit
                Write-Host "$($Lang.Switched_Model) $model ($($Lang.Respond_Token_Limit) $respondTokenLimit)" -ForegroundColor Green
            } else {
                Write-Host $Lang.Unknown_option_Original_settings_will_be_maintained -ForegroundColor Yellow
            }

            # 選擇模式
            Write-Host $Lang.Please_select_a_mode_1Steady_2Default_3Creative
            $temperatureChoice = Read-Host $Lang.Your_choice

            # 模式設定字典
            $temperatureSettings = [ordered]@{
                "1" = @{Temperature = 0.2; Message = $Lang.Set_to_Steady_mode}
                "2" = @{Temperature = 0.7; Message = $Lang.Set_to_Default_mode}
                "3" = @{Temperature = 1.0; Message = $Lang.Set_to_Creative_mode}
            }

            if ($temperatureSettings.Keys -contains ($temperatureChoice)) {
                $temperature = $temperatureSettings[$temperatureChoice].Temperature
                Write-Host $temperatureSettings[$temperatureChoice].Message -ForegroundColor Green
            } else {
                Write-Host $Lang.Unknown_option_Original_settings_will_be_maintained -ForegroundColor Yellow
            }

            Write-Host $Lang.Settings_completed_Returning_to_the_main_menu -ForegroundColor Cyan
            continue
        }
        "save" {
            Save-MessageHistory
            continue
        }
        "load" {
            Load-MessageHistory
            continue
        }
        "read" {
            $userMessage = ""
            Write-Host $Lang.Please_drag_the_text_file_you_want_to_read_into_the_window -ForegroundColor Cyan
            $filePath = Read-Host
            Try {
                $userMessage = $Lang.The_content_of_the_file_read_is + (Get-Content -Path $filePath -ErrorAction Stop)
                Write-Host $Lang.File_read_successfully -ForegroundColor Green
            }
            Catch {
                Write-Host $Lang.File_read_error -ForegroundColor Red
                continue
            }
        }
        "usage" {
            $fakeUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:135.0) Gecko/20100101 Firefox/135.0"
            $jsonData = curl -sX GET https://api.openai.com/dashboard/billing/credit_grants `
                        -H "Content-Type: application/json" `
                        -H "User-Agent: $fakeUserAgent" `
                        -H "Authorization: $WebToken"
        
            $response = $jsonData | ConvertFrom-Json
        
            if ($response.error) {
                # 檢查是否有錯誤訊息，並且是 API Key 錯誤
                if ($response.error.code -eq "invalid_api_key") {
                    Write-Host $Lang.Error $response.error.message -ForegroundColor Red
                    Write-Host $Lang.Reminder_to_get_bear_token -ForegroundColor Yellow
                    # 等待使用者輸入新的 Token
                    $newToken = Read-Host -Prompt $Lang.Please_enter_the_new_Web_Token_including_Bearer
                    # 儲存到環境變數
                    setx OPENAI_WEB_TOKEN "$newToken"
                    $WebToken = "$newToken"
                    Write-Host $Lang.The_new_Web_Token_has_been_saved_to_the_environment_variable_OPENAI_WEB_TOKEN -ForegroundColor Green
                } else {
                    # 處理其他可能的錯誤
                    Write-Host $Lang.Error -ForegroundColor Red
                    Write-Host $Lang.Error_type $($response.error.type) -ForegroundColor Yellow
                    Write-Host $Lang.Error_message ($response.error.message) -ForegroundColor Yellow
                }
            } else {
                $date = Get-Date -Format "yyyy-MM-dd HH:mm"
                Write-Host $date $lang.Remaining_balance $response.total_available $Lang.Total_usage_cost $response.total_used -ForegroundColor Yellow
            }
            continue
        }
        "upload" {
            Upload-Image
            continue
        }
        "image" {
            Show-CurrentImageSettings
            Write-Host $Lang.Please_select_an_option_1Optimize_prompts_and_generate_image_2Generate_image_with_original_prompts_3Settings
            $versionChoice = Read-Host $Lang.Your_choice
            if ($versionChoice -eq "3") {
                # Enter settings mode
                Write-Host $Lang.Enter_settings_mode
        
                # Change model
                Write-Host $Lang.Please_select_a_model_1DALL_E_2_2DALL_E_3
                $modelChoice = Read-Host $Lang.Your_choice
                if ($modelOptions.keys -contains ($modelChoice)) {
                    $currentModel = $modelOptions[$modelChoice]
                    Write-Host $Lang.Switched_to_model $currentModel -ForegroundColor Green
                } else {
                    Write-Host $Lang.Unknown_option_Original_settings_will_be_maintained -ForegroundColor Yellow
                }
                
                # Change size
                Write-Host $Lang.Please_select_a_size
                $sizeChoice = Read-Host $Lang.Your_choice
                if ($sizeOptions.Keys -contains ($sizeChoice)) {
                    $currentSize = $sizeOptions[$sizeChoice]
                    Write-Host $Lang.Size_set_to $currentSize -ForegroundColor Green
                } else {
                    Write-Host $Lang.Unknown_option_Original_settings_will_be_maintained -ForegroundColor Yellow
                }
        
                # Change quality
                Write-Host $Lang.Please_select_a_quality
                $qualityChoice = Read-Host $Lang.Your_choice
                if ($qualityOptions.keys -contains ($qualityChoice)) {
                    $currentQuality = $qualityOptions[$qualityChoice]
                    Write-Host $Lang.Quality_set_to $currentQuality  -ForegroundColor Green
                } else {
                    Write-Host $Lang.Unknown_option_Original_settings_will_be_maintained -ForegroundColor Yellow
                }
        
                # Return to main image interface
                Write-Host $Lang.Settings_completed -ForegroundColor Cyan
                continue
            }
            # 使用創建圖片函數並帶入使用的選擇模式參數
            if ($versionChoice -eq "1" -or $versionChoice -eq "2") {
                Process-ImageCreation $versionChoice
            } else {
                Write-Host $Lang.Unknown_choice_Please_re_enter -ForegroundColor Yellow
            }
            continue
        }
        default {
            # Add new user prompt to list of messages
            $MessageHistory.Add(@{
                "role" = "user"
                "content" = @(@{"type" = "text"; "text" = $userMessage})
            })

            # Query ChatGPT
            try {
                $tokenCount = [int](Calculate-MessageTokens -MessageHistory $MessageHistory)
            }
            catch {
                Write-Host $Lang.An_error_occurred_while_calculating_Token -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                $tokenCount = 0  # 提供一個預設值避免後續錯誤
            }
            
            Write-Host $Lang.Processing $model $Lang.Sent_this_time_using $tokenCount $Lang.Tokens -ForegroundColor DarkGray
            # 檢查是否接近 Token 上限
            $currentModelSetting = $models.GetEnumerator() | Where-Object { $_.Value.Model -eq $model } | Select-Object -First 1
            if ($tokenCount -ge ($currentModelSetting.Value.contextTokenLimit * 0.9)) {
                $remainingTokens = $currentModelSetting.Value.contextTokenLimit - $tokenCount
                Write-Host $Lang.Warning_There_are $contextTokenLimit $Lang.Tokens_left_until_the_token_limit_of $remainingTokens $Lang.Is_reached -ForegroundColor Red
            }

            try {
                $aiResponse = Invoke-ChatGPT $MessageHistory
            }
            catch {
                Write-Host $Lang.An_error_occurred_while_calling_ChatGPT -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                continue
            }
            
            # 格式化 AI 回應
            $aiMessageHashtable = Format-AiResponse -aiResponse $aiResponse
            if (-not $aiMessageHashtable) {
                continue
            }

            # 計算 AI 回應的 tokens
            $aiResponseTokenCount = Calculate-AiResponseTokens -aiMessageHashtable $aiMessageHashtable

            # 顯示 AI 回應
            Write-Host "AI: $aiResponse" -ForegroundColor Yellow
            Write-Host $Lang.Respond_this_time_using $aiResponseTokenCount $Lang.Tokens -ForegroundColor DarkGray

            # 將 AI 回應加入 MessageHistory
            $MessageHistory.Add($aiMessageHashtable)
        }
    }
}