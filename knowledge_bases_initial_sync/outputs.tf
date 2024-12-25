output "knowledge_bases_py" {
  value = <<EOT
################################################
# Oregon
################################################
REGION = '${local.oregon}'  # リージョンを記載
KNOWLEDGEBASE_ID = '${aws_bedrockagent_knowledge_base.oregon.id}'  # ナレッジベース ID を記載
EOT
}
