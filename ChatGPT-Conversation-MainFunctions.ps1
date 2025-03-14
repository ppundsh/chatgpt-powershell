# Clears the message history and fills it with the system message (and allows us to reset the history and start a new conversation)
Function Initialize-MessageHistory ($message){
    $script:MessageHistory.Clear()
    $script:MessageHistory.Add(@{"role" = "system"; "content" = $message}) | Out-Null
}

# Function to send a message to ChatGPT. (We need to pass the entire message history in each request since we're using a RESTful API)
Function Invoke-ChatGPT ($MessageHistory) {
    # 取得當前模型的設定
    $currentModelSetting = $models.GetEnumerator() | Where-Object { $_.Value.Model -eq $model } | Select-Object -First 1

    # Set the request headers
    $headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $ApiKey"
    }   

    # Set the request body
    if ($currentModelSetting.Value.modelType -eq "reasoning") {
        $requestBody = @{
            "model" = $model
            "messages" = $MessageHistory
            "max_completion_tokens" = $currentModelSetting.Value.respondTokenLimit
        }
    } else {
        $requestBody = @{
            "model" = $model
            "messages" = $MessageHistory
            "max_tokens" = $currentModelSetting.Value.respondTokenLimit
            "temperature" = $temperature
        }
    }

    # Send the request
    $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Headers $headers -Body (ConvertTo-Json -Depth 5 $requestBody)

    # Extract message content
    $aiContent = $response.choices[0].message.content

    # 如果返回的內容不是陣列，則包裝成陣列
    if ($aiContent -isnot [System.Collections.IEnumerable]) {
        $aiContent = @(@{"type" = "text"; "text" = $aiContent})
    }

    return $aiContent
}

# Display current Image settings
Function Show-CurrentImageSettings {
    Write-Host "$($Lang.Current_settings)model: 【$currentModel】 size: 【$currentSize】 quality: 【$currentQuality】" -ForegroundColor Cyan
}

# Process-ImageCreation
Function Process-ImageCreation($versionChoice) {
    do {
        Write-Host $Lang.Please_enter_a_prompt_for_creating_an_image_Enter_exit_to_leave_the_image_creation_Function
        $inputLine = Read-Host

        if ($inputLine -eq "exit") {
            break
        }

        # 根據版本選擇來決定是否最佳化提示詞
        if ($versionChoice -eq "1") {
            # 發送提示詞給 ChatGPT 進行最佳化
            $MessageHistory.Add(@{"role"="user"; "content"="$DalleOptimizationMessage $inputLine"})
            Write-Host $Lang.Optimizing
            $optimizedPrompt = Invoke-ChatGPT $MessageHistory

            Write-Host $Lang.Optimized_prompt $optimizedPrompt
            $aiResponse = Invoke-Dalle $optimizedPrompt
        } else {
            $aiResponse = Invoke-Dalle $inputLine
        }

        # 解析 JSON 回應
        $responseJson = $aiResponse | ConvertFrom-Json
        # 提取 URL 並顯示
        if ($responseJson.error) {
            Write-Host $Lang.Error_type $($responseJson.error.code)
            Write-Host $Lang.Error_message $($responseJson.error.message)
        } else {
            foreach ($item in $responseJson.data) {
                $imageUrl = $item.url
                Write-Host $Lang.Generated_image_URL $imageUrl
                Start-Process $imageUrl  # 自動開啟瀏覽器
            }
        }
    } while ($true) # 持續重複直到輸入 exit
}

# Invoke-Dalle
Function Invoke-Dalle($message){
    $body = @{
        model = $currentModel
        prompt = $message
        n = 1
        size = $currentSize
        quality= $currentQuality
    } | ConvertTo-Json
    try {
        $response = curl https://api.openai.com/v1/images/generations `
            -H "Content-Type: application/json" `
            -H "Authorization: Bearer $ApiKey" `
            -d $body
        return $response
    }
    catch {
        Write-Host $Lang.Image_generation_API_call_failed -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Save MessageHistory to gpt_history.log in plain text format
Function Save-MessageHistory {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath "ChatGPT-Conversation_history.log"
    try {
        $jsonContent = $MessageHistory | ConvertTo-Json -Depth 5
    }
    catch {
        Write-Host $Lang.An_error_occurred_while_saving_the_conversation_history_file -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    Set-Content -Path $filePath -Value $jsonContent -Encoding UTF8
    Write-Host $Lang.Conversation_history_has_been_saved_to $filePath -ForegroundColor Green
}

# Load MessageHistory from gpt_history.log in plain text format
Function Load-MessageHistory {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath "ChatGPT-Conversation_history.log"
    if (Test-Path $filePath) {
        # 讀取 JSON 格式的內容並解析
        try {
            $jsonContent = Get-Content -Path $filePath -Raw
        }
        catch {
            Write-Host $Lang.An_error_occurred_while_reading_the_conversation_history_file -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
        $jsonArray = $jsonContent | ConvertFrom-Json

        # 轉換為 List[Hashtable]
        $script:MessageHistory = [System.Collections.Generic.List[Hashtable]]::new()
        foreach ($item in $jsonArray) {
            # 把 PSCustomObject 轉換成 Hashtable
            $hashtableItem = @{}
            foreach ($key in $item.PSObject.Properties.Name) {
                $hashtableItem[$key] = $item.$key
            }
            $script:MessageHistory.Add($hashtableItem)
        }

        Write-Host $Lang.Conversation_history_has_been_loaded -ForegroundColor Green
    } else {
        Write-Host $Lang.Gpt_history_log_file_not_found -ForegroundColor Red
    }
}

# Function to encode image to Base64
Function Encode-ImageToBase64 ($imagePath) {
    if (-Not (Test-Path $imagePath)) {
        Write-Host $Lang.No_image_found_at_the_specified_path_Please_verify_if_the_path_is_correct -ForegroundColor Red
        return $null
    }
    try {
        [Byte[]]$imageBytes = [System.IO.File]::ReadAllBytes($imagePath)
        return [Convert]::ToBase64String($imageBytes)
    }
    catch {
        Write-Host $Lang.Image_reading_failed_Please_confirm_whether_the_path_or_file_is_correct -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $null
    }
}

# Function to upload an image
Function Upload-Image {
    $imagePath = Read-Host $Lang.Enter_the_path_to_upload_the_image
    $base64Image = Encode-ImageToBase64 $imagePath

    if ($base64Image) {
        Write-Host $Lang.Image_uploading
        $messageContent = @{
            role = "user"
            content = @(
                @{
                    type = "image_url"
                    image_url = @{ url = "data:image/jpeg;base64,$base64Image" }
                }
            )
        }

        $MessageHistory.Add($messageContent)

        # Send the request to OpenAI
        $response = Invoke-ChatGPT $MessageHistory
        Write-Host "AI:" -ForegroundColor Yellow
        Write-Host $response
    }
}

# Function to calclate message tokens
Function Calculate-MessageTokens {
    param (
        [System.Collections.Generic.List[Hashtable]]$MessageHistory
    )

    # 將對話歷史轉換成 JSON 字串
    $jsonContent = $MessageHistory | ConvertTo-Json -Depth 5 -Compress

    # 建立一個臨時檔案來儲存 JSON 字串
    $tempFilePath = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFilePath -Value $jsonContent -Encoding UTF8

    $pythonScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "ChatGPT-Conversation-tiktoken.py"

    # 呼叫 Python 腳本，並將臨時檔案的路徑作為參數傳遞
    try {
        $tokenCount = & python $pythonScriptPath $tempFilePath 2>&1 | Out-String
        $tokenCount = $tokenCount.Trim()
    }
    catch {
        Write-Host $Lang.Token_calculation_Python_script_call_failed -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $tokenCount = 0
    }

    # 清除臨時檔案
    Remove-Item -Path $tempFilePath

    return $tokenCount
}

# 格式化 AI 回應並建立 Hashtable
Function Format-AiResponse {
    param (
        [Parameter(Mandatory=$true)]
        [object]$aiResponse
    )

    $contentForJson = $null
    # 這裡做明確的格式判斷處理
    if ($aiResponse -is [string]) {
        # 如果直接是一個字串，直接使用
        $aiTextContent = $aiResponse.Trim()
        $contentForJson = $aiTextContent
    }
    elseif ($aiResponse -is [System.Collections.IEnumerable]) {
        # 如果是陣列 (例如 @(@{type=...;text=...}))
        $aiTextContent = ($aiResponse | Where-Object {$_ -is [hashtable] -and $_.ContainsKey("text")} | Select-Object -ExpandProperty "text") -join ""
        # 這裡我們仍要傳完整格式給 Python
        $contentForJson = $aiResponse
    }
    else {
        Write-Host $Lang.Unable_to_recognize_the_format_of_the_AI_response -ForegroundColor Red
        return $null
    }

    # 建立要送給 Python 的 Hashtable
    $aiMessageHashtable = @{
        "role" = "assistant"
        "content" = $contentForJson
    }

    return $aiMessageHashtable
}

# 計算 AI 回應的 tokens
Function Calculate-AiResponseTokens {
    param (
        [hashtable]$aiMessageHashtable
    )

    # 寫入暫存檔案
    $tempAiResponseFile = [System.IO.Path]::GetTempFileName()
    $aiMessageHashtable | ConvertTo-Json -Depth 5 | Set-Content -Path $tempAiResponseFile -Encoding utf8

    # 呼叫 Python 計算 token
    try {
        $aiResponseTokenCount = & python "$PSScriptRoot\ChatGPT-Conversation-tiktoken.py" $tempAiResponseFile 2>&1 | Out-String
        $aiResponseTokenCount = [int]($aiResponseTokenCount.Trim())
    }
    catch {
        Write-Host $Lang.An_error_occurred_while_calculating_the_AI_response_token -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $aiResponseTokenCount = 0 # 回傳預設值以避免錯誤
    }
    finally {
        # 清除暫存檔案
        Remove-Item -Path $tempAiResponseFile -Force
    }

    return $aiResponseTokenCount
}

# 錯誤處理函式
Function Handle-Error ($errorMessage) {
    Write-Host $Lang.Error $errorMessage -ForegroundColor Red
}