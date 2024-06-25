import os
import json
import boto3
import streamlit as st

# 設定クラス
class Config:
    model_id = "anthropic.claude-3-haiku-20240307-v1:0"  # 使用するモデルのID
    system_prompt = "あなたはセキュリティギャルです。ギャル口調で喋ってください。"  # システムプロンプト
    temperature = 1.0
    top_k = 200
    guardrailConfig = {
        "guardrailIdentifier": os.getenv("GUARDRAIL_IDENTIFIER"),
        "guardrailVersion": os.getenv("GUARDRAIL_VERSION"),
        "trace": "enabled"
    }

# Bedrockクライアントを取得しキャッシュ
@st.cache_resource
def get_bedrock_client():
    return boto3.client(service_name="bedrock-runtime", region_name="us-west-2")

# モデルの呼び出しとレスポンスの生成
def generate_response(messages):
    bedrock_client = get_bedrock_client()
    system_prompts = [{"text": Config.system_prompt}]
    inference_config = {"temperature": Config.temperature}
    additional_model_fields = {"top_k": Config.top_k}

    # Converse API の呼び出し
    response = bedrock_client.converse(
        modelId=Config.model_id,
        messages=messages,
        system=system_prompts,
        inferenceConfig=inference_config,
        additionalModelRequestFields=additional_model_fields,
        guardrailConfig=Config.guardrailConfig
    )
    return response


# チャット履歴を表示
def display_history(messages):
    for message in st.session_state.messages:
        display_msg_content(message)

# 個々のメッセージを表示する関数
def display_msg_content(message):
    with st.chat_message(message["role"]):
        if message["role"] == "user":
            st.write(message["content"][0]["guardContent"]["text"]["text"])
        else:
            st.write(message["content"][0]["text"])

def main():
    st.title("Bedrock Converse API Chatbot")

    # セッション状態にメッセージ履歴がない場合は初期化
    if "messages" not in st.session_state:
        st.session_state.messages = []

    # チャット履歴を表示
    display_history(st.session_state.messages)

    # ユーザー入力を受け取り、処理する
    if prompt := st.chat_input("What's up?"):
        input_msg = {"role": "user", "content": [{"guardContent": {"text": {"text": prompt}}}]}
        display_msg_content(input_msg)
        st.session_state.messages.append(input_msg)

        # AIからのレスポンスを生成し、表示する
        response = generate_response(st.session_state.messages)
        res_message = response["output"]["message"]
        # ガードレールによるブロックがある場合
        if response["stopReason"] == "guardrail_intervened":
            res_message = response["output"]["message"]
            display_msg_content(res_message)
            st.session_state.messages.append(res_message)
            display_msg_content({"role": "assistant", "content": [{"text": "User input removed chat history."}]})
            st.session_state.messages.remove(input_msg)
            st.write(response)
            trace = response["trace"]
            st.write("Guardrail trace:")
            st.write(json.dumps(trace["guardrail"], indent=4))
        else:
            display_msg_content(res_message)
            st.session_state.messages.append(res_message)

if __name__ == "__main__":
    main()