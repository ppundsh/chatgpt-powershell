<#
This script will let you have a conversation with ChatGPT.
It shows how to keep a history of all previous messages and feed them into the REST API in order to have an ongoing conversation.
#>

# Define API key and endpoint
$ApiKey = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY")
$WebToken = [System.Environment]::GetEnvironmentVariable("OPENAI_WEB_TOKEN")
$ApiEndpoint = "https://api.openai.com/v1/chat/completions"

<#
System message.
You can use this to give the AI instructions on what to do, how to act or how to respond to future prompts.
Default value for ChatGPT = "You are a helpful assistant."
#>
$AiSystemMessage = "You are a helpful assistant,以繁體中文回答,並且有著高中女生的口氣回覆專業的軟體工程訊息"

# Initialize default model
$model = "gpt-4o"
$temperature = 0.7 # Lower is more coherent and conservative, higher is more creative and diverse.

# 定義可選的模型,https://platform.openai.com/docs/models
$models = @{
    "1" = @{Model = "gpt-4.5-preview-2025-02-27"; tokenLimit = 5000; modelType = "chat"}
    "2" = @{Model = "gpt-4o"; tokenLimit = 8000; modelType = "chat"}
    "3" = @{Model = "o3-mini"; tokenLimit = 50000; modelType = "reasoning"}
    "4" = @{Model = "o1"; tokenLimit = 50000; modelType = "reasoning"}
}
# Token Limit: Max amount of tokens the AI will respond with
#model              Context window	Max output tokens
#gpt-4.5-preview    128,000 tokens  16,384 tokens
#gpt-4o-2024-08-06  128,000 tokens  16,384 tokens
#gpt-o3-min         200,000 tokens  100,000 tokens
#gpt-o1             200,000 tokens  100,000 tokens 

# Initialize default image settings
$currentModel = "dall-e-3"
$currentSize = "1024x1024"
$currentQuality = "standard"

# we use this list to store the system message and will add any user prompts and ai responses as the conversation evolves.
[System.Collections.Generic.List[Hashtable]]$MessageHistory = @()

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
            "max_completion_tokens" = $currentModelSetting.Value.tokenLimit
        }
    } else {
        $requestBody = @{
            "model" = $model
            "messages" = $MessageHistory
            "max_tokens" = $currentModelSetting.Value.tokenLimit
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
    Write-Host "當前設定：model: 【$currentModel】 size: 【$currentSize】 quality: 【$currentQuality】" -ForegroundColor Cyan

}

# CreatImageSetting
Function CreatImageSetting ($message){
    $body = @{
        model = "dall-e-3"
        prompt = $message
        n = 1
        size = "1024x1024"
    } | ConvertTo-Json

    $response = curl https://api.openai.com/v1/images/generations `
        -H "Content-Type: application/json" `
        -H "Authorization: Bearer $ApiKey" `
        -d $body

    return $response
}

# CreatImageFunction
Function ProcessImageCreation($versionChoice) {
    do {
        Write-Host "請輸入創建圖片的提示詞（輸入 'exit' 離開創建圖片功能）"
        $inputLine = Read-Host

        if ($inputLine -eq "exit") {
            break
        }

        # 根據版本選擇來決定是否最佳化提示詞
        if ($versionChoice -eq "1") {
            # 發送提示詞給 ChatGPT 進行最佳化
            $MessageHistory.Add(@{"role"="user"; "content"="將以下提示詞最佳化為更明確的表達的內容、強烈的風格和精緻且豐富 的細節的 prompt，具有大師級作品的細緻，回覆內容要直接交付給 Dell-e-3，只需要回覆 prompt 即可：$inputLine"})
            $optimizedPrompt = Invoke-ChatGPT $MessageHistory

            Write-Host "`n最佳化後的提示詞: $optimizedPrompt"
            $aiResponse = CreatImageSetting $optimizedPrompt
        } else {
            $aiResponse = CreatImageSetting $inputLine
        }

        # 解析 JSON 回應
        $responseJson = $aiResponse | ConvertFrom-Json
        # 提取 URL 並顯示
        if ($responseJson.error) {
            Write-Host "錯誤代碼: $($responseJson.error.code)"
            Write-Host "錯誤訊息: $($responseJson.error.message)"
        } else {
            foreach ($item in $responseJson.data) {
                $imageUrl = $item.url
                Write-Host "`n生成的圖片 URL: $imageUrl"
                Start-Process $imageUrl  # 自動開啟瀏覽器
            }
        }
    } while ($true) # 持續重複直到輸入 exit
}

# Save MessageHistory to gpt_history.log in plain text format
Function Save-MessageHistory {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath "gpt_history.log"
    $jsonContent = $MessageHistory | ConvertTo-Json -Depth 5
    Set-Content -Path $filePath -Value $jsonContent -Encoding UTF8
    Write-Host "對話歷史已保存到 $filePath" -ForegroundColor Green
}
# Load MessageHistory from gpt_history.log in plain text format
Function Load-MessageHistory {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath "gpt_history.log"
    if (Test-Path $filePath) {
        # 讀取 JSON 格式的內容並解析
        $jsonContent = Get-Content -Path $filePath -Raw
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

        Write-Host "對話歷史已從 gpt_history.log 載入" -ForegroundColor Green
    } else {
        Write-Host "找不到 gpt_history.log 檔案" -ForegroundColor Red
    }
}

# Function to encode image to Base64
Function Encode-ImageToBase64 ($imagePath) {
    if (-Not (Test-Path $imagePath)) {
        Write-Host "找不到該路徑的圖片，請確認路徑是否正確。" -ForegroundColor Red
        return $null
    }
    [Byte[]]$imageBytes = [System.IO.File]::ReadAllBytes($imagePath)
    return [Convert]::ToBase64String($imageBytes)
}

# Function to upload an image
Function Upload-Image {
    $imagePath = Read-Host "請輸入要上傳圖片的路徑"
    $base64Image = Encode-ImageToBase64 $imagePath

    if ($base64Image) {
        Write-Host "圖片上傳中..."
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

    $pythonScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "ChatGPT-tiktoken.py"

    # 呼叫 Python 腳本，並將臨時檔案的路徑作為參數傳遞
    $tokenCount = & python $pythonScriptPath $tempFilePath 2>&1 | Out-String
    $tokenCount = $tokenCount.Trim() # 去除多餘的空白字符

    # 清除臨時檔案
    Remove-Item -Path $tempFilePath

    return $tokenCount
}
# Show startup text
Clear-Host
Write-Host "###############################`n# ChatGPT ($model) Powershell #`n###############################`n`nEnter your prompt to continue." -ForegroundColor Yellow
Write-Host "`nType 'eof' to switch to paragraph input mode,`nType 'read' to Read a plain text file,`nType 'image' to use DALL-E to creat an image,`nType 'upload' to upload an image for Vision,`nType 'save' to save the chat history or 'load' to load the chat history.`nType 'usage' to check incurred fees.`nType 'setting' to set model and temperature.`nType 'exit' to quit or 'reset' to start a new chat." -ForegroundColor Yellow

# Add system message to MessageHistory
Initialize-MessageHistory $AiSystemMessage

# Main loop
while ($true) {
    # Capture user input
    $userMessage = Read-Host "`nYou"
    if ($userMessage -eq "eof") {
        $userMessage = ""
        Write-Host "請輸入你的文章，當完成輸入請在新的一行輸入 'EOF' 來結束："
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
            Write-Host "請選擇一個模型："
            $models.GetEnumerator() | ForEach-Object {
                Write-Host "$($_.Key). $($_.Value.Model)：	Respond Token Limit: $($_.Value.tokenLimit)	Type: $($_.Value.modelType)"
            }
            $modelChoice = Read-Host "`n你的選擇"

            if ($models.ContainsKey($modelChoice)) {
                $model = $models[$modelChoice].Model
                $tokenLimit = $models[$modelChoice].tokenLimit
                Write-Host "已切換至模型：$model (Respond Token Limit: $tokenLimit)" -ForegroundColor Green
            } else {
                Write-Host "未知的選項，將維持原設定。" -ForegroundColor Yellow
            }

            # 選擇模式
            Write-Host "請選擇一個模式：`n1. 穩重`n2. 預設`n3. 創意"
            $temperatureChoice = Read-Host "`n你的選擇"

            # 模式設定字典
            $temperatureSettings = @{
                "1" = @{Temperature = 0.2; Message = "已設定為穩重模式。"}
                "2" = @{Temperature = 0.7; Message = "已設定為預設模式。"}
                "3" = @{Temperature = 1.0; Message = "已設定為創意模式。"}
            }

            if ($temperatureSettings.ContainsKey($temperatureChoice)) {
                $temperature = $temperatureSettings[$temperatureChoice].Temperature
                Write-Host $temperatureSettings[$temperatureChoice].Message -ForegroundColor Green
            } else {
                Write-Host "未知的選項，將維持原設定。" -ForegroundColor Yellow
            }

            Write-Host "設定完成，返回主選單。" -ForegroundColor Cyan
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
            Write-Host "請將要讀取的純文字檔案拖到視窗：" -ForegroundColor Cyan
            $filePath = Read-Host
            Try {
                $userMessage = "The content of the file read is：" + (Get-Content -Path $filePath -ErrorAction Stop)
                Write-Host "`n檔案讀取成功" -ForegroundColor Green
            }
            Catch {
                Write-Host "`n讀取錯誤" -ForegroundColor Red
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
                    Write-Host "錯誤：$($response.error.message)" -ForegroundColor Red
                    Write-Host "提醒：使用瀏覽器前往 https://platform.openai.com/usage 並複製 GET 'credit_grants' 所使用的請求標頭 'Authorization'" -ForegroundColor Yellow
                    # 等待使用者輸入新的 Token
                    $newToken = Read-Host -Prompt "請輸入新的 Web Token (包含 Bearer)"
                    # 儲存到環境變數
                    setx OPENAI_WEB_TOKEN "$newToken"
                    $WebToken = "$newToken"
                    Write-Host "新的 Web Token 已儲存到環境變數 'OPENAI_WEB_TOKEN'。" -ForegroundColor Green
                } else {
                    # 處理其他可能的錯誤
                    Write-Host "發生其他錯誤：" -ForegroundColor Red
                    Write-Host "錯誤類型：$($response.error.type)"regroundColor Yellow
                    Write-Host "錯誤訊息：$($response.error.message) -Fo" -ForegroundColor Yellow
                }
            } else {
                $date = Get-Date -Format "yyyy-MM-dd HH:mm"
                Write-Host "$date`n剩餘費用  ：$($response.total_available)`n共使用費用：$($response.total_used)" -ForegroundColor Yellow
            }
            continue
        }
        "upload" {
            Upload-Image
            continue
        }
        "image" {
            Show-CurrentImageSettings
            Write-Host "`n請選擇一個選項：`n1. 最佳化提示詞並生成圖片`n2. 原始提示詞生成圖片`n3. 設定"
            $versionChoice = Read-Host "`n你的選擇"
            if ($versionChoice -eq "3") {
                # Enter settings mode
                Write-Host "進入設定模式："
        
                # Change model
                Write-Host "請選擇模型：`n1. DALL·E 2`n2. DALL·E 3"
                $modelChoice = Read-Host "`n你的選擇"
                switch ($modelChoice) {
                    "1" {
                        $currentModel = "dall-e-2"
                        Write-Host "已切換至模型：dall-e-2" -ForegroundColor Green
                    }
                    "2" {
                        $currentModel = "dall-e-3"
                        Write-Host "已切換至模型：dall-e-3" -ForegroundColor Green
                    }
                    default {
                        Write-Host "未知的選項，模型維持不變。" -ForegroundColor Yellow
                    }
                }
        
                # Change size
                Write-Host "請選擇尺寸：`n1. 256x256 (DALL·E 2 Only)`n2. 512x512 (DALL·E 2 Only)`n3. 1024x1024`n4. 1024x1792 (DALL·E 3 Only)`n5. 1792x1024 (DALL·E 3 Only)"
                $sizeChoice = Read-Host "`n你的選擇"
                $sizeOptions = @{
                    "1" = "256x256"
                    "2" = "512x512"
                    "3" = "1024x1024"
                    "4" = "1024x1792"
                    "5" = "1792x1024"
                }
                # 判斷選擇
                if ($sizeOptions.ContainsKey($sizeChoice)) {
                    $currentSize = $sizeOptions[$sizeChoice]
                    Write-Host "已設定尺寸為：$currentSize" -ForegroundColor Green
                } else {
                    Write-Host "未知的選項，尺寸維持不變。" -ForegroundColor Yellow
                }
        
                # Change quality
                Write-Host "請選擇品質：`n1. standard`n2. hd (DALL·E 3 Only )"
                $qualityChoice = Read-Host "`n你的選擇"
                switch ($qualityChoice) {
                    "1" {
                        $currentQuality = "standard"
                        Write-Host "已設定品質為：standard" -ForegroundColor Green
                    }
                    "2" {
                        $currentQuality = "hd"
                        Write-Host "已設定品質為：hd" -ForegroundColor Green
                    }
                    default {
                        Write-Host "未知的選項，品質維持不變。" -ForegroundColor Yellow
                    }
                }
        
                # Return to main image interface
                Write-Host "設定完成。" -ForegroundColor Cyan
                continue
            }
            # 使用創建圖片函數並帶入使用的選擇模式參數
            if ($versionChoice -eq "1" -or $versionChoice -eq "2") {
                ProcessImageCreation $versionChoice
            } else {
                Write-Host "未知的選擇，請重新輸入。" -ForegroundColor Yellow
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
            $tokenCount = [int](Calculate-MessageTokens -MessageHistory $MessageHistory)
            Write-Host "...處理中 ( $model 已使用 token : $tokenCount)...`n" -ForegroundColor DarkGray
            # 檢查是否接近 Token 上限
            if ($tokenCount -ge 120000) {
                $remainingTokens = $tokenLimit - $tokenCount
                Write-Host "警告：距離 token 上限 $tokenLimit 還剩下 $remainingTokens 個" -ForegroundColor Red
            }

            $aiResponse = Invoke-ChatGPT $MessageHistory

            # Show response
            Write-Host "AI: $aiResponse" -ForegroundColor Yellow

            # Add ChatGPT response to list of messages
            $MessageHistory.Add(@{
                "role" = "assistant"
                "content" = @(@{"type" = "text"; "text" = $aiResponse})
            })
        }
    }
}