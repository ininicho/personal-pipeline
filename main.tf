terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
    # cloudflare = {
    #   source = "cloudflare/cloudflare"
    #   version = "~> 4.0"
    # }
  }
  backend "s3" {}
}

provider "aws" {
  region = "us-east-2"
  profile = var.profile_name
}

resource "aws_resourcegroups_group" "rg" {
  name = "personal-pipeline-rg"
  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": [
    {
      "Key": "Project",
      "Values": [
        "PersonalPipeline"
      ]
    }
  ]
}
JSON
  }
}

locals {
  ses_to_s3_rule_name = "store_in_s3"
}

resource "aws_s3_bucket" "inbox" {
  bucket = "nick-inbox"

  tags = {
    Project = "PersonalPipeline"
  }
}

resource "aws_s3_bucket_policy" "ses_to_s3_policy" {
  bucket = aws_s3_bucket.inbox.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowSESPuts"
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.inbox.bucket}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = var.aws_account_id
            "AWS:SourceArn" = "arn:aws:ses:${var.aws_region}:${var.aws_account_id}:receipt-rule-set/${aws_ses_receipt_rule_set.personal_pipeline_set.rule_set_name}:receipt-rule/${local.ses_to_s3_rule_name}"
          }
        }
      }
    ]
  })
}

resource "aws_ses_domain_identity" "ininicho" {
  domain = "ininicho.com"
}

resource "aws_ses_receipt_rule_set" "personal_pipeline_set" {
  rule_set_name = "personal_pipeline_set"
}

resource "aws_ses_receipt_rule" "store_in_s3" {
  name = local.ses_to_s3_rule_name
  rule_set_name = aws_ses_receipt_rule_set.personal_pipeline_set.rule_set_name
  recipients = ["add@ininicho.com"]
  enabled = true
  scan_enabled = true

  add_header_action {
    header_name  = "Custom-Header"
    header_value = "Added by SES"
    position     = 1
  }

  s3_action {
    bucket_name = aws_s3_bucket.inbox.bucket
    position    = 2
  }

  depends_on = [
    aws_s3_bucket_policy.ses_to_s3_policy
  ]
}

resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = aws_ses_receipt_rule_set.personal_pipeline_set.rule_set_name
}

