import tiktoken
import json
import sys

def calculate_tokens(messages, model='gpt-4o'):
    encoding = tiktoken.encoding_for_model(model)
    total_tokens = 0
    for message in messages:
        # 確保 content 是字串
        content = message.get('content', '')
        if isinstance(content, list):  # 如果 content 是個列表
            content = ''.join(item['text'] for item in content if 'text' in item)
        elif not isinstance(content, str):
            content = str(content)

        total_tokens += len(encoding.encode(content))
    return total_tokens

if __name__ == "__main__":
    # 從文件中讀取 JSON 字串
    file_path = sys.argv[1]
    with open(file_path, 'r', encoding='utf-8') as file:
        message_history = json.load(file)

    # 計算 token 數
    token_count = calculate_tokens(message_history)
    print(token_count)