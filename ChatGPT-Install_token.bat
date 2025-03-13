@echo off
setx OPENAI_API_KEY "Your_OpenAI_API_Key"
echo Successfully added OPENAI_API_KEY to the environment variables
setx OPENAI_WEB_TOKEN "Bearer Your_Bearer_Token"
echo Successfully added OPENAI_WEB_TOKEN to the environment variables
echo Install OpenAI Tiktoken
pip install openai tiktoken
pause