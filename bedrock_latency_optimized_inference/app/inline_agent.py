import boto3
import time
from uuid import uuid4
from pprint import pprint

################################################
# Ohio
################################################
REGION = 'us-east-2'  # リージョンを記載

session_id = str(uuid4())
bedrock_agent_runtime = boto3.client('bedrock-agent-runtime', region_name=REGION)
model_id = "us.anthropic.claude-3-5-haiku-20241022-v1:0"

inputText = """
桃太郎はどこで生まれましたか？
"""

response = bedrock_agent_runtime.invoke_inline_agent(
    sessionId=session_id,
    inputText=inputText,
    endSession=False,
    enableTrace=True,
    foundationModel=model_id,
    bedrockModelConfigurations={'performanceConfig': {'latency': option}},
    instruction="物知りです。ユーザから入力された質問に対して、己の頭のみ気合いで回答します。",
)

options = ['standard', 'optimized']

for option in options:
    start = time.time() 
    response = bedrock_agent_runtime.invoke_inline_agent(
        sessionId=session_id,
        inputText=inputText,
        endSession=False,
        enableTrace=True,
        foundationModel=model_id,
        bedrockModelConfigurations={'performanceConfig': {'latency': option}},
        instruction="あなたは、ユーザの代わりにコードを実行するエージェントです。ユーザから入力されたコードをCodeInterpreterActionを使って実行します。",
        actionGroups=[
            {
                'actionGroupName': 'CodeInterpreterAction',
                'parentActionGroupSignature': 'AMAZON.CodeInterpreter'
            }
        ],
    )

    # レスポンスを格納する変数
    trace_data = None
    output_text = ""

    # イベントストリームを処理
    for event in response['completion']:
        if 'trace' in event:
            trace_data = event['trace']['trace']['orchestrationTrace']
        if 'chunk' in event:
            output_text += event['chunk']['bytes'].decode('utf-8')

    # 結果を表示
    print(option, time.time() - start)