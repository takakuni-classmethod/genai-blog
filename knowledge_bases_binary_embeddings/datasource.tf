########################################################
# Data Source
########################################################
module "datasource" {
  source = "../modules/datasource"

  prefix = "${local.prefix}-${local.region}"
  datasource = {
    force_destroy = true
  }
}

########################################################
# Put Object
########################################################
resource "aws_s3_object" "momotarou_chapter1" {
  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第1章.txt"
  # アップロード先(S3)
  key    = "桃太郎第1章.txt"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第1章.txt")
}
resource "aws_s3_object" "momotarou_chapter2" {
  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第2章.txt"
  # アップロード先(S3)
  key    = "桃太郎第2章.txt"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第2章.txt")
}
resource "aws_s3_object" "momotarou_chapter3" {
  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第3章.txt"
  # アップロード先(S3)
  key    = "桃太郎第3章.txt"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第3章.txt")
}

resource "aws_s3_object" "momotarou_chapter4" {
  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第4章.txt"
  # アップロード先(S3)
  key    = "桃太郎第4章.txt"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第4章.txt")
}
