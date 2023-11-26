resource "aws_ses_domain_identity" "ininicho" {
  domain = "ininicho.com"
}

resource "aws_ses_receipt_rule_set" "personal_finance_pipeline_set" {
  rule_set_name = "personal_finance_pipeline_set"
}

resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = aws_ses_receipt_rule_set.personal_finance_pipeline_set.rule_set_name
}

resource "aws_ses_receipt_rule" "amex_email_rule" {
  name = "${local.ses_to_s3_rule_name}_amex"
  rule_set_name = aws_ses_receipt_rule_set.personal_finance_pipeline_set.rule_set_name
  recipients = ["amex@ininicho.com"]
  enabled = true
  scan_enabled = true

  add_header_action {
    header_name  = "Bank"
    header_value = "AMEX"
    position     = 1
  }

  # TODO: Add a lambda action to parse the email and send it to the database

  s3_action {
    bucket_name = aws_s3_bucket.inbox.bucket
    position    = 2
  }

  depends_on = [
    aws_s3_bucket_policy.ses_to_s3_policy
  ]
}

resource "aws_ses_receipt_rule" "cibc_email_rule" {
  name = "${local.ses_to_s3_rule_name}_cibc"
  rule_set_name = aws_ses_receipt_rule_set.personal_finance_pipeline_set.rule_set_name
  recipients = ["cibc@ininicho.com"]
  enabled = true
  scan_enabled = true

  add_header_action {
    header_name  = "Bank"
    header_value = "CIBC"
    position     = 1
  }

  # TODO: Add a lambda action to parse the email and send it to the database

  s3_action {
    bucket_name = aws_s3_bucket.inbox.bucket
    position    = 2
  }

  depends_on = [
    aws_s3_bucket_policy.ses_to_s3_policy
  ]
}

