########################################################
# Network Policy
########################################################
resource "aws_opensearchserverless_security_policy" "this_network" {
  name        = "${local.prefix}-network-policy"
  type        = "network"
  description = "${local.prefix}-network-policy"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "dashboard",
          Resource = [
            "collection/${local.prefix}-collection"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            "collection/${local.prefix}-collection"
          ]
        }
      ],
      AllowFromPublic = true
    }
  ])
}

########################################################
# Encryption Policy
########################################################
resource "aws_opensearchserverless_security_policy" "this_encryption" {
  name        = "${local.prefix}-encryption-policy"
  type        = "encryption"
  description = "${local.prefix}-encryption-policy"
  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection",
        Resource = [
          "collection/${local.prefix}-collection"
        ]
      }
    ],
    AWSOwnedKey = true
  })
}

########################################################
# Data Access Policy
########################################################
resource "aws_opensearchserverless_access_policy" "this_data" {
  name        = "${local.prefix}-data-policy"
  type        = "data"
  description = "${local.prefix}-data-policy"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            "collection/${local.prefix}-collection"
          ],
          Permission = [
            "aoss:DescribeCollectionItems",
            "aoss:CreateCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DeleteCollectionItems"
          ]
        },
        {
          ResourceType = "index",
          Resource = [
            "index/${local.prefix}-collection/*"
          ],
          Permission = [
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:DescribeIndex",
            "aoss:CreateIndex",
            "aoss:UpdateIndex",
            "aoss:DeleteIndex"
          ],
        },
      ],
      Principal = [
        aws_iam_role.knowledge_bases.arn,
        "${join("/", slice(tolist(split("/", data.aws_caller_identity.this.arn)), 0, 2))}/*" # For terraform credentials
      ]
    }
  ])
}

########################################################
# Collection
########################################################
resource "aws_opensearchserverless_collection" "this" {
  name             = "${local.prefix}-collection"
  description      = "${local.prefix}-collection"
  type             = "VECTORSEARCH"
  standby_replicas = "DISABLED"

  depends_on = [
    aws_opensearchserverless_security_policy.this_network,
    aws_opensearchserverless_security_policy.this_encryption,
    aws_opensearchserverless_access_policy.this_data
  ]
}

########################################################
# Index
########################################################
resource "opensearch_index" "this" {
  name          = "${local.prefix}-vector-index"
  index_knn     = true
  force_destroy = true
  mappings = jsonencode({
    dynamic_templates = [
      {
        strings = {
          match_mapping_type = "string"
          mapping = {
            fields = {
              keyword = {
                type         = "keyword"
                ignore_above = 2147483647
              }
            }
            type = "text"
          }
        }
      }
    ]
    properties = {
      "${local.prefix}-vector" = {
        type      = "knn_vector",
        data_type = "BINARY",
        dimension = var.knowledge_bases.embeddings_model_dimensions,
        method = {
          space_type = "hamming",
          engine     = "faiss",
          name       = "hnsw"
          parameters = {}
        }
      },
      AMAZON_BEDROCK_METADATA = {
        type  = "text",
        index = false
      },
      AMAZON_BEDROCK_TEXT_CHUNK = {
        type = "text"
      },
      AMAZON_BEDROCK_TEXT = {
        type = "text"
        fields = {
          keyword = {
            type = "keyword"
          }
        }
      },
      id = {
        fields = {
          keyword = {
            type = "keyword"
          }
        }
        type = "text"
      },
      x-amz-bedrock-kb-data-source-id = {
        fields = {
          keyword = {
            type = "keyword"
          }
        }
        type = "text"
      },
      x-amz-bedrock-kb-source-uri = {
        fields = {
          keyword = {
            type = "keyword"
          }
        }
        type = "text"
      }
    }
  })
  depends_on = [
    aws_opensearchserverless_security_policy.this_network,
    aws_opensearchserverless_security_policy.this_encryption,
    aws_opensearchserverless_access_policy.this_data
  ]
}
