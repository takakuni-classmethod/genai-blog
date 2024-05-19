import os
import boto3
import streamlit as st

kb_id = os.environ.get("KNOWLEDGE_BASE_ID")
model_arn = "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
kb = boto3.client("bedrock-agent-runtime", region_name="us-east-1")

st.title("Knowledge bases for Amazon Bedrock chat")

# Initialize chat history
if "messages" not in st.session_state:
    st.session_state.messages = []

# Initialize session ID
if "session_id" not in st.session_state:
    st.session_state.session_id = None

# Display chat messages from history on app rerun
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])
        if message["role"] == "assistant":
            st.write(f"Session ID: {st.session_state.session_id}")

# Accept user input
if prompt := st.chat_input("聞きたいことを入力してね"):
    # Add user message to chat history
    st.session_state.messages.append({"role": "user", "content": prompt})
    # Display user message in chat message container
    with st.chat_message("user"):
        st.markdown(prompt)
    # Display assistant response in chat message container
    with st.chat_message("assistant"):
        params = {
            "input": {"text": prompt},
            "retrieveAndGenerateConfiguration": {
                "type": "KNOWLEDGE_BASE",
                "knowledgeBaseConfiguration": {
                    "knowledgeBaseId": kb_id,
                    "modelArn": model_arn,
                },
            },
        }
        if st.session_state.session_id is not None:
            params["sessionId"] = st.session_state.session_id
        response = kb.retrieve_and_generate(**params)
        st.markdown(response["output"]["text"])
        with st.expander("引用"):
            st.json(response["citations"])
        st.session_state.session_id = response["sessionId"]
        st.write(f"Session ID: {st.session_state.session_id}")
    # Add assistant response to chat history
    st.session_state.messages.append(
        {"role": "assistant", "content": response["output"]["text"]}
    )

if st.button(
    "チャット履歴の削除",
    on_click=lambda: exec(
        "st.session_state.messages = []; st.session_state.session_id = None"
    ),
):
    pass
