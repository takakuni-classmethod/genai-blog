import boto3
from uuid import uuid4

AWS_ACCOUNT_ID = '123456789012'  # AWS アカウント ID を記載

################################################
# Ohio
################################################
REGION = 'us-east-2'  # リージョンを記載
AGENT_ID = 'F48G7VBRQ5'  # エージェント ID を記載
AGENT_ALIAS_ID = 'T3HCO5U8NN'  # エージェントエイリアス ID を記載

# ################################################
# # Virginia
# ################################################
# REGION = 'us-east-1'  # リージョンを記載
# AGENT_ID = 'YQNK0L9C9C'  # エージェント ID を記載
# AGENT_ALIAS_ID = 'LJKZOSUGUS'  # エージェントエイリアス ID を記載

# ################################################
# # Oregon
# ################################################
# REGION = 'us-west-2'  # リージョンを記載
# AGENT_ID = '4QTBERXYCV'  # エージェント ID を記載
# AGENT_ALIAS_ID = '4KBDMYC2KZ'  # エージェントエイリアス ID を記載

latency = 'standard'
# latency = 'optimized'

session_id = str(uuid4())

input_text = '桃太郎はどこで生まれましたか？'
bedrock_agent_runtime = boto3.client('bedrock-agent-runtime', region_name=REGION)

# Agentの実行
response = bedrock_agent_runtime.invoke_agent(
    inputText=input_text,
    agentId=AGENT_ID,
    agentAliasId=AGENT_ALIAS_ID,
    sessionId=session_id,
    enableTrace=False,
    bedrockModelConfigurations={
        'performanceConfig': {
            'latency': latency
        }
    },
)

# Agent実行結果の取得
event_stream = response['completion']
for event in event_stream:        
    if 'chunk' in event:
        data = event['chunk']['bytes'].decode('utf-8')
        print(data)