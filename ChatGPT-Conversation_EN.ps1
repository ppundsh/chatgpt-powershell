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
$AiSystemMessage = "You are a helpful assistant"

# Initialize default model
$model = "gpt-4o"
$temperature = 0.7 # Lower is more coherent and conservative, higher is more creative and diverse.

# Define optional models, https://platform.openai.com/docs/models
# respondTokenLimit: Max amount of tokens the AI will respond with
$models = [ordered]@{
    "1" = @{Model = "gpt-4o"; respondTokenLimit = 8000; contextTokenLimit = 128000; modelType = "chat"}
    "2" = @{Model = "gpt-4.5-preview-2025-02-27"; respondTokenLimit = 5000; contextTokenLimit = 128000 ;modelType = "chat"}
    "3" = @{Model = "o3-mini"; respondTokenLimit = 50000; contextTokenLimit = 200000; modelType = "reasoning"}
    "4" = @{Model = "o1"; respondTokenLimit = 50000; contextTokenLimit = 200000; modelType = "reasoning"}
    "5" = @{Model = "gpt-4o-search-preview"; respondTokenLimit = 5000; contextTokenLimit = 128000; modelType = "reasoning"}
}
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
    # Get the current model settings
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

    # If the returned content is not an array, wrap it as an array
    if ($aiContent -isnot [System.Collections.IEnumerable]) {
        $aiContent = @(@{"type" = "text"; "text" = $aiContent})
    }

    return $aiContent
}

# Display current Image settings
Function Show-CurrentImageSettings {
    Write-Host "Current settings:model: 【$currentModel】 size: 【$currentSize】 quality: 【$currentQuality】" -ForegroundColor Cyan

}

# Process-ImageCreation
Function Process-ImageCreation($versionChoice) {
    do {
        Write-Host "Please enter a prompt for creating an image (enter 'exit' to leave the image creation Function)."
        $inputLine = Read-Host

        if ($inputLine -eq "exit") {
            break
        }

        # Decide whether to optimize the prompt based on the version choice.
        if ($versionChoice -eq "1") {
            # Send the prompt to ChatGPT for optimization.
            $MessageHistory.Add(@{"role"="user"; "content"="Optimize the following prompt words into a more explicit expression, strong style, and delicate and rich details, with the meticulousness of a master's work. The reply content should be delivered directly to Dell-e-3. Just reply to the prompt: $inputLine"})
            Write-Host "`nOptimizing..."
            $optimizedPrompt = Invoke-ChatGPT $MessageHistory

            Write-Host "`nOptimized prompt: $optimizedPrompt"
            $aiResponse = Invoke-Dalle $optimizedPrompt
        } else {
            $aiResponse = Invoke-Dalle $inputLine
        }

        # Parse the JSON response.
        $responseJson = $aiResponse | ConvertFrom-Json
        # Extract the URL and display it.
        if ($responseJson.error) {
            Write-Host "Error code: $($responseJson.error.code)"
            Write-Host "Error message: $($responseJson.error.message)"
        } else {
            foreach ($item in $responseJson.data) {
                $imageUrl = $item.url
                Write-Host "`nGenerated image URL: $imageUrl`n"
                Start-Process $imageUrl  # Automatically open the browser.
            }
        }
    } while ($true) # Continue repeating until input exit
}

# Invoke-Dalle
Function Invoke-Dalle ($message){
    $body = @{
        model = "dall-e-3"
        prompt = $message
        n = 1
        size = "1024x1024"
    } | ConvertTo-Json
    try {
        $response = curl https://api.openai.com/v1/images/generations `
            -H "Content-Type: application/json" `
            -H "Authorization: Bearer $ApiKey" `
            -d $body
        return $response
    }
    catch {
        Write-Host "⚠️ 圖片生成 API 呼叫失敗：" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Save MessageHistory to gpt_history.log in plain text format
Function Save-MessageHistory {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath "gpt_history.log"
    try {
        $jsonContent = $MessageHistory | ConvertTo-Json -Depth 5
    }
    catch {
        Write-Host "⚠️ An error occurred while saving the conversation history file:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    Set-Content -Path $filePath -Value $jsonContent -Encoding UTF8
    Write-Host "Conversation history has been saved to $filePath" -ForegroundColor Green
}

# Load MessageHistory from gpt_history.log in plain text format
Function Load-MessageHistory {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath "gpt_history.log"
    if (Test-Path $filePath) {
        # Read and parse JSON-formatted content
        try {
            $jsonContent = Get-Content -Path $filePath -Raw
        }
        catch {
            Write-Host "⚠️ An error occurred while reading the conversation history file:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
        $jsonArray = $jsonContent | ConvertFrom-Json

        # Convert to List[Hashtable]
        $script:MessageHistory = [System.Collections.Generic.List[Hashtable]]::new()
        foreach ($item in $jsonArray) {
            # Convert PSCustomObject to Hashtable
            $hashtableItem = @{}
            foreach ($key in $item.PSObject.Properties.Name) {
                $hashtableItem[$key] = $item.$key
            }
            $script:MessageHistory.Add($hashtableItem)
        }

        Write-Host "Conversation history has been loaded from gpt_history.log" -ForegroundColor Green
    } else {
        Write-Host "gpt_history.log file not found" -ForegroundColor Red
    }
}

# Function to encode image to Base64
Function Encode-ImageToBase64 ($imagePath) {
    if (-Not (Test-Path $imagePath)) {
        Write-Host "No image found at the specified path, please verify if the path is correct." -ForegroundColor Red
        return $null
    }
    try {
        [Byte[]]$imageBytes = [System.IO.File]::ReadAllBytes($imagePath)
        return [Convert]::ToBase64String($imageBytes)
    }
    catch {
        Write-Host "⚠️ Image reading failed, please confirm whether the path or file is correct:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $null
    }
}

# Function to upload an image
Function Upload-Image {
    $imagePath = Read-Host "Enter the path to upload the image"
    $base64Image = Encode-ImageToBase64 $imagePath

    if ($base64Image) {
        Write-Host "Image uploading..."
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

    # Convert conversation history to a JSON string
    $jsonContent = $MessageHistory | ConvertTo-Json -Depth 5 -Compress

    # Create a temporary file to store the JSON string
    $tempFilePath = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFilePath -Value $jsonContent -Encoding UTF8

    $pythonScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "ChatGPT-tiktoken.py"

    # Call the Python script and pass the path of the temporary file as an argument
    try {
        $tokenCount = & python $pythonScriptPath $tempFilePath 2>&1 | Out-String
        $tokenCount = $tokenCount.Trim()
    }
    catch {
        Write-Host "⚠️ Token calculation (Python script) call failed:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $tokenCount = 0
    }

    # Clear temporary files
    Remove-Item -Path $tempFilePath

    return $tokenCount
}

# Error Handling Function
Function Handle-Error ($errorMessage) {
    Write-Host "⚠️ An error occurred $errorMessage" -ForegroundColor Red
}

# Show startup text
Clear-Host
Write-Host "###############################`n# ChatGPT ($model) Powershell #`n###############################`n`nEnter your prompt to continue." -ForegroundColor Yellow
Write-Host "`nType 'eof' to switch to paragraph input mode,`nType 'read' to Read a plain text file,`nType 'image' to use DALL-E to creat an image,`nType 'upload' to upload an image for Vision,`nType 'save' to save the chat history or 'load' to load the chat history.`nType 'usage' to check incurred fees.`nType 'setting' to set model and temperature.`nType 'exit' to quit or 'reset' to start a new chat." -ForegroundColor Yellow

# Check apikey
if (-not $ApiKey) {
    Write-Host "No API Key is set. Please set the OPENAI_API_KEY environment variable." -ForegroundColor Red
    exit
}

# Add system message to MessageHistory
Initialize-MessageHistory $AiSystemMessage

# Main loop
while ($true) {
    # Capture user input
    $userMessage = Read-Host "`nYou"
    if ($userMessage -eq "eof") {
        $userMessage = ""
        Write-Host "Please enter your text, and when you are finished, type 'EOF' on a new line to end:"
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
            # Show available models
            Write-Host "Please select a model:"
            $models.GetEnumerator() | ForEach-Object {
                Write-Host "$($_.Key). $($_.Value.Model):	Respond Token Limit: $($_.Value.tokenLimit)	Type: $($_.Value.modelType)"
            }
            $modelChoice = Read-Host "`nYour choice"

            if ($models.Keys -contains $modelChoice) {
                $model = $models[$modelChoice].Model
                $tokenLimit = $models[$modelChoice].tokenLimit
                Write-Host "Switched to Model:$model (Respond Token Limit: $tokenLimit)" -ForegroundColor Green
            } else {
                Write-Host "Unknown option, original settings will be maintained." -ForegroundColor Yellow
            }

            # Switched to model
            Write-Host "Please select a mode:`n1. Steady`n2. Default`n3. Creative"
            $temperatureChoice = Read-Host "`nYour Choice"

            # Pattern Configuration Dictionary
            $temperatureSettings = [ordered]@{
                "1" = @{Temperature = 0.2; Message = "Set to Steady mode."}
                "2" = @{Temperature = 0.7; Message = "Set to Default mode."}
                "3" = @{Temperature = 1.0; Message = "Set to Creative mode."}
            }

            if ($temperatureSettings.Keys -contains ($temperatureChoice)) {
                $temperature = $temperatureSettings[$temperatureChoice].Temperature
                Write-Host $temperatureSettings[$temperatureChoice].Message -ForegroundColor Green
            } else {
                Write-Host "Unknown option, will maintain original settings." -ForegroundColor Yellow
            }

            Write-Host "Settings completed, returning to the main menu." -ForegroundColor Cyan
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
            Write-Host "Please drag the text file you want to read into the window:" -ForegroundColor Cyan
            $filePath = Read-Host
            Try {
                $userMessage = "The content of the file read is:" + (Get-Content -Path $filePath -ErrorAction Stop)
                Write-Host "`nFile read successfully" -ForegroundColor Green
            }
            Catch {
                Write-Host "`nFile read error" -ForegroundColor Red
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
                # Check for error messages, and if it is an API Key error
                if ($response.error.code -eq "invalid_api_key") {
                    Write-Host "Error:$($response.error.message)" -ForegroundColor Red
                    Write-Host "Reminder: Use a browser to go to https://platform.openai.com/usage and copy the request header 'Authorization' used in GET 'credit_grants'" -ForegroundColor Yellow
                    # Waiting for the user to enter a new Token
                    $newToken = Read-Host -Prompt "Please enter the new Web Token (including Bearer)"
                    # Save to environment variables
                    setx OPENAI_WEB_TOKEN "$newToken"
                    $WebToken = "$newToken"
                    Write-Host "The new Web Token has been saved to the environment variable 'OPENAI_WEB_TOKEN''。" -ForegroundColor Green
                } else {
                    # Handle other possible errors
                    Write-Host "An error occurred:" -ForegroundColor Red
                    Write-Host "Error type:$($response.error.type)"regroundColor Yellow
                    Write-Host "Error message:$($response.error.message) -Fo" -ForegroundColor Yellow
                }
            } else {
                $date = Get-Date -Format "yyyy-MM-dd HH:mm"
                Write-Host "$date`nRemaining balance  :$($response.total_available)`nTotal usage cost:$($response.total_used)" -ForegroundColor Yellow
            }
            continue
        }
        "upload" {
            Upload-Image
            continue
        }
        "image" {
            Show-CurrentImageSettings
            Write-Host "`nPlease select an option:`n1. Optimize prompts and generate image`n2. Generate image with original prompts`n3. Settings"
            $versionChoice = Read-Host "`nYour choice"
            if ($versionChoice -eq "3") {
                # Enter settings mode
                Write-Host "Enter settings mode:"
        
                # Change model
                Write-Host "Please select a model:`n1. DALL·E 2`n2. DALL·E 3"
                $modelChoice = Read-Host "`nYour choice"
                switch ($modelChoice) {
                    "1" {
                        $currentModel = "dall-e-2"
                        Write-Host "Switched to model:dall-e-2" -ForegroundColor Green
                    }
                    "2" {
                        $currentModel = "dall-e-3"
                        Write-Host "Switched to model:dall-e-3" -ForegroundColor Green
                    }
                    default {
                        Write-Host "Unknown option, model remains unchanged." -ForegroundColor Yellow
                    }
                }
        
                # Change size
                Write-Host "Please select a size:`n1. 256x256 (DALL·E 2 Only)`n2. 512x512 (DALL·E 2 Only)`n3. 1024x1024`n4. 1024x1792 (Only DALL·E 3)`n5. 1792x1024 (DALL·E 3 Only)"
                $sizeChoice = Read-Host "`nYour choice"
                $sizeOptions = [ordered]@{
                    "1" = "256x256"
                    "2" = "512x512"
                    "3" = "1024x1024"
                    "4" = "1024x1792"
                    "5" = "1792x1024"
                }
                # 判斷選擇
                if ($sizeOptions.Keys -contains ($sizeChoice)) {
                    $currentSize = $sizeOptions[$sizeChoice]
                    Write-Host "Size set to:$currentSize" -ForegroundColor Green
                } else {
                    Write-Host "Unknown option, size remains unchanged." -ForegroundColor Yellow
                }
        
                # Change quality
                Write-Host "Please select a quality:`n1. standard`n2. hd (DALL·E 3 only)"
                $qualityChoice = Read-Host "`nYour choice"
                switch ($qualityChoice) {
                    "1" {
                        $currentQuality = "standard"
                        Write-Host "Quality set to:standard" -ForegroundColor Green
                    }
                    "2" {
                        $currentQuality = "hd"
                        Write-Host "Quality set to:hd" -ForegroundColor Green
                    }
                    default {
                        Write-Host "Unknown option, quality remains unchanged." -ForegroundColor Yellow
                    }
                }
        
                # Return to main image interface
                Write-Host "Settings completed." -ForegroundColor Cyan
                continue
            }
            # Use the image creation Function and pass in the chosen mode parameter.
            if ($versionChoice -eq "1" -or $versionChoice -eq "2") {
                Process-ImageCreation $versionChoice
            } else {
                Write-Host "Unknown choice, please re-enter." -ForegroundColor Yellow
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
                Write-Host "⚠️ An error occurred while calculating Token:：" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                $tokenCount = 0  # Give a preset value to avoid subsequent errors
            }
            
            Write-Host "...Processing ( $model sent this time using [$tokenCount tokens])...`n" -ForegroundColor DarkGray
            # Check if the token limit is approaching.
            $currentModelSetting = $models.GetEnumerator() | Where-Object { $_.Value.Model -eq $model } | Select-Object -First 1
            if ($tokenCount -ge ($currentModelSetting.Value.contextTokenLimit  * 0.9)) {
                $remainingTokens = $currentModelSetting.Value.contextTokenLimit - $tokenCount
                Write-Host "Warning: There are $contextTokenLimit tokens left until the token limit of $remainingTokens is reached." -ForegroundColor Red
            }

            try {
                $aiResponse = Invoke-ChatGPT $MessageHistory
            }
            catch {
                Write-Host "⚠️ An error occurred while calling ChatGPT:" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                continue
            }
            
            # Here we do clear format judgment processing
            if ($aiResponse -is [string]) {
                # If it is a string directly, use it directly
                $aiTextContent = $aiResponse.Trim()
                $contentForJson = $aiTextContent
            }
            elseif ($aiResponse -is [System.Collections.IEnumerable]) {
                # If it is an array (for example @(@{type=...;text=...}))
                $aiTextContent = ($aiResponse | Where-Object {$_ -is [hashtable] -and $_.ContainsKey("text")} | Select-Object -ExpandProperty "text") -join ""
                # Here we still need to pass the complete format to Python
                $contentForJson = $aiResponse
            }
            else {
                Write-Host "⚠️ Unable to recognize the format of the AI ​​response!" -ForegroundColor Red
                continue
            }

            # Create a Hashtable to send to Python
            $aiMessageHashtable = @{
                "role" = "assistant"
                "content" = $contentForJson
            }
            
            # Write to temporary file
            $tempAiResponseFile = [System.IO.Path]::GetTempFileName()
            $aiMessageHashtable | ConvertTo-Json -Depth 5 | Set-Content -Path $tempAiResponseFile -Encoding utf8
            
            # Debug
            #Write-Host "JSON content passed to Python:"
            #Get-Content $tempAiResponseFile | Write-Host -ForegroundColor Magenta

            # Call Python to calculate token
            try {
                $aiResponseTokenCount = & python "$PSScriptRoot\ChatGPT-tiktoken.py" $tempAiResponseFile 2>&1 | Out-String
                $aiResponseTokenCount = [int]($aiResponseTokenCount.Trim())
                # Show AI Response
                Write-Host "AI: $aiResponse" -ForegroundColor Yellow
                Write-Host "This response used [$aiResponseTokenCount tokens]" -ForegroundColor DarkGray
            }
            catch {
                Write-Host "⚠️ An error occurred while calculating the AI ​​response token:" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                # Here you can choose to print out the Python return content to confirm the reason for failure
                Write-Host "Python returns the following content:$aiResponseTokenCount" -ForegroundColor Red
            }
            finally {
                # Clear temporary files
                Remove-Item -Path $tempAiResponseFile -Force
            }
            
            # Add AI responses to MessageHistory
            $MessageHistory.Add($aiMessageHashtable)
        }
    }
}