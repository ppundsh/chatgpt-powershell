# 🤖 ChatGPT PowerShell Scripts 🚀

[![GitHub license](https://img.shields.io/github/license/yzwijsen/chatgpt-powershell)](https://github.com/yzwijsen/chatgpt-powershell/blob/main/LICENSE)

This repository contains a PowerShell scripts that allow you to interact with OpenAI's ChatGPT 🧠:

1. **ChatGPT-Conversation.ps1**: Engage in a conversational manner with ChatGPT using a command-line interface.
2. **ChatGPT-Install_token.bat**: Store OpenAI_API_Key and Bearer_Token in environment variables and install OpenAI Tiktoken
3. **ChatGPT-tiktoken.py**: Calculate the current token usage.

## ⚙️ Requirements

- PowerShell
- Python
- An API key for OpenAI's API

## 🛠️ Setup

1. Clone or download this repository to your local machine.
2. Replace `<Your_OpenAI_API_Key>` in ChatGPT-Install_token.bat with your OpenAI API key 🔑.
3. Use a browser to go to https://platform.openai.com/usage and copy the request header 'Authorization' used in GET 'credit_grants', replace `<Your_Bearer_Token>` in ChatGPT-Install_token.bat with your 'Authorization'.
4. Execute ChatGPT-Install_token.bat .
5. For security reasons, delete ChatGPT-Install_token.bat .

## 🛠️ Optional

Quickly start the script after entering gpt in PowerShell.
In PowerShell, enter `notepad $profile`
Insert the following
```
function gpt {& 'C:\the_script_path\ChatGPT-Conversation_CHT.ps1'}
```
Restart PowerShell or run `$profile` to load the new settings.

## 🚀 Usage

### ChatGPT-Conversation.ps1

1. Open PowerShell and navigate to the folder containing the script 📁.
2. Execute the script: `.\ChatGPT-Conversation_EN.ps1` 🖥️.
3. You'll see a welcome message and a prompt to enter your question or command 🎤.
4. Type your question or command and press Enter ⌨️.
5. The AI will respond with its output 💬.
6. Type 'eof' to switch to paragraph input mode,
7. Type 'read' to Read a plain text file,
8. Type 'image' to use DALL-E to creat an image,
9. Type 'upload' to upload an image for Vision,
10. Type 'save' to save the chat history
11. Type 'load' to load the chat history.
12. Type 'usage' to check incurred fees.
13. Type 'setting' to set model and temperature.
14. To exit the script, type `exit` and press Enter 🚪.
15. To reset the conversation and start a new one, type `reset` and press Enter 🔄.


## 📝 Notes
The scripts initialize the AI with a default system message. You can change this message to set a different context for the AI by modifying the $AiSystemMessage variable.
ChatGPT-Conversation.ps1 will keep track of the conversation history, allowing the AI to provide context-aware answers.