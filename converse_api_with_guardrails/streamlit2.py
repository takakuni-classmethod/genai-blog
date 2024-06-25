import os
import json
import boto3
import streamlit as st

# 設定クラス
class Config:
    model_id = "anthropic.claude-3-haiku-20240307-v1:0"  # 使用するモデルのID
    system_prompt = "you are security consultant"  # システムプロンプト
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


def main():
    st.title("Bedrock Converse API Chatbot")

    # セッション状態にメッセージ履歴がない場合は初期化
    if "messages" not in st.session_state:
        st.session_state.messages = []

    # 再実行時に履歴からチャットメッセージを表示
    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])

    # Accept user input
    if prompt := st.chat_input("What is up?"):
        st.chat_message("user").markdown(prompt)
        input_msg = {"role": "user", "content": [{"guardContent": {"text": {"text": prompt}}}]}
        st.session_state.messages.append(input_msg)
        response = generate_response(st.session_state.messages)
        output_msg = response["output"]["message"]
        st.write(response)
        # ガードレールによるブロックがある場合
        if response["stopReason"] == "guardrail_intervened":
            with st.chat_message("assistant"):
                st.markdown(output_msg["content"][0]["text"])
                st.session_state.messages.remove(input_msg)
                st.write(st.session_state.messages)
        else:
            with st.chat_message("assistant"):
                st.markdown(output_msg["content"][0]["text"])
                # st.session_state.messages.remove(input_msg)
                # st.session_state.messages.append({"role": "user", "content": prompt})
                st.session_state.messages.append(output_msg)

        # st.write(response)
        # with st.chat_message(response["output"]["message"]["role"]):
        #     st.write(response["content"][0]["guardContent"]["text"]["text"])
        # res_message = response["output"]["message"]
        # # ガードレールによるブロックがある場合
        # if response["stopReason"] == "guardrail_intervened":
        #     with st.chat_message("assistant"):
        #         st.write(res_message["guardContent"]["text"]["text"])
        # # Display user message in chat message container
        # with st.chat_message("user"):
        #     st.markdown(prompt)

        # # Display assistant response in chat message container
        # with st.chat_message("assistant"):
        #     response = st.write_stream(response_generator())
        # # Add assistant response to chat history
        # st.session_state.messages.append({"role": "assistant", "content": response})

if __name__ == "__main__":
    main()