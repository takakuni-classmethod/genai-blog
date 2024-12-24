output "agents_py" {
  value = <<EOT
################################################
# Ohio
################################################
REGION = '${local.ohio}'  # リージョンを記載
AGENT_ID = '${aws_bedrockagent_agent.ohio.agent_id}'  # エージェント ID を記載
AGENT_ALIAS_ID = '${aws_bedrockagent_agent_alias.ohio.agent_alias_id}'  # エージェントエイリアス ID を記載

################################################
# Virginia
################################################
REGION = '${local.virginia}'  # リージョンを記載
AGENT_ID = '${aws_bedrockagent_agent.virginia.agent_id}'  # エージェント ID を記載
AGENT_ALIAS_ID = '${aws_bedrockagent_agent_alias.virginia.agent_alias_id}'  # エージェントエイリアス ID を記載

################################################
# Oregon
################################################
REGION = '${local.oregon}'  # リージョンを記載
AGENT_ID = '${aws_bedrockagent_agent.oregon.agent_id}'  # エージェント ID を記載
AGENT_ALIAS_ID = '${aws_bedrockagent_agent_alias.oregon.agent_alias_id}'  # エージェントエイリアス ID を記載
EOT
}

output "knowledge_bases_py" {
  value = <<EOT
################################################
# Ohio
################################################
REGION = '${local.ohio}'  # リージョンを記載
KNOWLEDGEBASE_ID = '${aws_bedrockagent_knowledge_base.ohio.id}'  # ナレッジベース ID を記載

################################################
# Virginia
################################################
REGION = '${local.virginia}'  # リージョンを記載
KNOWLEDGEBASE_ID = '${aws_bedrockagent_knowledge_base.virginia.id}'  # ナレッジベース ID を記載

################################################
# Oregon
################################################
REGION = '${local.oregon}'  # リージョンを記載
KNOWLEDGEBASE_ID = '${aws_bedrockagent_knowledge_base.oregon.id}'  # ナレッジベース ID を記載
EOT
}
