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

