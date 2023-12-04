# Inbox Bucket
resource "aws_s3_bucket" "inbox" {
  bucket = "nick-finances-inbox"
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
          }
          ArnLike = {
            "AWS:SourceArn" = "arn:aws:ses:${var.aws_region}:${var.aws_account_id}:receipt-rule-set/${aws_ses_receipt_rule_set.personal_finance_pipeline_set.rule_set_name}:receipt-rule/${local.ses_to_s3_rule_name}*"
          }
        }
      }
    ]
  })
}

# Expense Bucket
resource "aws_s3_bucket" "expense" {
  bucket = "nick-finances-expense"
}

