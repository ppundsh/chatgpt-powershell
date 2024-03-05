<#
This script will let you have a conversation with ChatGPT.
It shows how to keep a history of all previous messages and feed them into the REST API in order to have an ongoing conversation.
#>

# Define API key and endpoint
$ApiKey = "<your API key>"
$ApiEndpoint = "https://api.openai.com/v1/chat/completions"
$Credit_grantsBearer = "<your Credit grantsBearer>"

<#
System message.
You can use this to give the AI instructions on what to do, how to act or how to respond to future prompts.
Default value for ChatGPT = "You are a helpful assistant."
#>
$AiSystemMessage = "You are a helpful assistant,以繁體中文回答,並且回覆專業的工程訊息"

# we use this list to store the system message and will add any user prompts and ai responses as the conversation evolves.
[System.Collections.Generic.List[Hashtable]]$MessageHistory = @()

# Clears the message history and fills it with the system message (and allows us to reset the history and start a new conversation)
Function Initialize-MessageHistory ($message){
    $script:MessageHistory.Clear()
    $script:MessageHistory.Add(@{"role" = "system"; "content" = $message}) | Out-Null
}

# Function to send a message to ChatGPT. (We need to pass the entire message history in each request since we're using a RESTful API)
function Invoke-ChatGPT ($MessageHistory) {
    # Set the request headers
    $headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $ApiKey"
    }   

    # Set the request body
    $requestBody = @{
 #       "model" = "gpt-3.5-turbo"
 #       "model" = "gpt-4"
        "model" = "gpt-4-turbo-preview"
        "messages" = $MessageHistory
        "max_tokens" = 1000 # Max amount of tokens the AI will respond with
        "temperature" = $temperature
    }

    # Send the request
    $response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Headers $headers -Body (ConvertTo-Json $requestBody)

    # Return the message content
    return $response.choices[0].message.content
}

# Default Setting
$temperature = 0.7 # Lower is more coherent and conservative, higher is more creative and diverse.

# Show startup text
Clear-Host
Write-Host "######################`n# ChatGPT Powershell #`n######################`n`nEnter your prompt to continue. `n(type 'exit' to quit or 'reset' to start a new chat, type 'eof' to switch to paragraph input mode type 'read' to Read a plain text file, Use 'usage' to query incurred fees.)" -ForegroundColor Yellow

# Add system message to MessageHistory
Initialize-MessageHistory $AiSystemMessage

# Main loop
while ($true) {
    # Capture user input
    $userMessage = Read-Host "`nYou"

    # Check if user wants to exit or reset
    if ($userMessage -eq "exit") {
        break
    }
    if ($userMessage -eq "reset") {
        # Reset the message history so we can start with a clean slate
        Initialize-MessageHistory $AiSystemMessage

        Write-Host "Messages reset." -ForegroundColor Yellow
        continue
    }
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
    if ($userMessage -eq "set") {
        Write-Host "請選擇一個模式：`n1. 穩重`n2. 標準`n3. 創意"
        $choice = Read-Host "`n你的選擇"
        switch ($choice) {
            "1" {
                $temperature = 0.2
                Write-Host "已設定為穩重模式。" -ForegroundColor Green
            }
            "2" {
                $temperature = 0.7
                Write-Host "已維持為標準模式。" -ForegroundColor Green
            }
            "3" {
                $temperature = 1.6
                Write-Host "已設定為創意模式。" -ForegroundColor Green
            }
            default {
                Write-Host "未知的選項，將維持原設定。" -ForegroundColor Yellow
            }
        }
        continue
    }
    if ($userMessage -eq "read") {
        $userMessage = ""
        Write-Host "請將要讀取的純文字檔案拖到視窗：" -ForegroundColor Cyan
        $filePath = Read-Host
        Try {
            # 假設用戶正確拖曳檔案路徑後會復制進來
            $userMessage =  "The content of the file read is：" + (Get-Content -Path $filePath -ErrorAction Stop)
            Write-Host "`n檔案讀取成功" -ForegroundColor Green
        }
        Catch {
            Write-Host "`n讀取錯誤" -ForegroundColor Red
            continue
        }
    }
    if ($userMessage -eq "usage") {
        $jsonData = curl -sX GET https://api.openai.com/dashboard/billing/credit_grants -H "Content-Type: application/json"  -H "Authorization: Bearer $Credit_grantsBearer"
        $usage = $jsonData | ConvertFrom-Json
        $date = Get-Date -Format "yyyy-MM-dd HH:mm" 
        Write-Host "$date 總共使用費用：$($usage.total_used)" -ForegroundColor Yellow
        continue
    }

    # Add new user prompt to list of messages
    $MessageHistory.Add(@{"role"="user"; "content"=$userMessage})

    # Query ChatGPT
    Write-Host "...處裡中...`n" -ForegroundColor DarkGray
    $aiResponse = Invoke-ChatGPT $MessageHistory

    # Show response
    Write-Host "AI: $aiResponse" -ForegroundColor Yellow

    # Add ChatGPT response to list of messages
    $MessageHistory.Add(@{"role"="assistant"; "content"=$aiResponse})
}
