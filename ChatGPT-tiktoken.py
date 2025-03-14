import tiktoken
import json
import sys

def calculate_tokens(messages, model='gpt-4o'):
    encoding = tiktoken.encoding_for_model(model)
    total_tokens = 0
    for message in messages:
        if isinstance(message, dict):
            content = message.get('content', '')
            if isinstance(content, list):
                content = ''.join(item.get('text', '') for item in content if isinstance(item, dict))
            elif not isinstance(content, str):
                content = str(content)
        else:
            content = str(message)
        total_tokens += len(encoding.encode(content))
    return total_tokens

def calculate_single_message_tokens(message, model='gpt-4o'):
    encoding = tiktoken.encoding_for_model(model)
    if isinstance(message, dict):
        content = message.get('content', '')
        if isinstance(content, list):
            content = ''.join(item.get('text', '') for item in content if isinstance(item, dict))
        elif not isinstance(content, str):
            content = str(content)
    else:
        content = str(message)
    return len(encoding.encode(content))

if __name__ == "__main__":
    file_path = sys.argv[1]
    with open(file_path, 'r', encoding='utf-8') as file:
        data = json.load(file)

    # 自動判斷傳入的參數是單一訊息(dict)還是一個訊息列表(list)
    if isinstance(data, list):
        print(calculate_tokens(data))
    elif isinstance(data, dict):
        print(calculate_single_message_tokens(data))
    else:
        print(0)