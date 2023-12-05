# Policy: ReadWriteS3, LambdaLogging
resource "aws_iam_policy" "read_write_s3" {
  name        = "ReadWriteS3"
  description = "Read and write to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::*/*"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "LambdaLogging"
  description = "Allow Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda Role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "email_lambda_role" {
  name               = "email_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "email_lambda_role_attachment" {
  role       = aws_iam_role.email_lambda_role.name
  policy_arn = aws_iam_policy.read_write_s3.arn
}

resource "aws_iam_role_policy_attachment" "email_lambda_logging_attachment" {
  role       = aws_iam_role.email_lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role" "processor_lambda_role" {
  name               = "processor_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "processor_lambda_role_attachment" {
  role       = aws_iam_role.processor_lambda_role.name
  policy_arn = aws_iam_policy.read_write_s3.arn
}

resource "aws_iam_role_policy_attachment" "processor_lambda_logging_attachment" {
  role       = aws_iam_role.processor_lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# Cloudwatch Group
resource "aws_cloudwatch_log_group" "email" {
  name              = "/aws/lambda/${aws_lambda_function.email.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "processor" {
  name             = "/aws/lambda/${aws_lambda_function.processor.function_name}"
  retention_in_days = 7
}

# Lambda
data "archive_file" "email_lambda" {
  type        = "zip"
  source_dir  = "email_lambda"
  output_path = "email_lamba_payload.zip"
}

resource "aws_lambda_function" "email" {
  filename      = data.archive_file.email_lambda.output_path
  function_name = "email_processor"
  role          = aws_iam_role.email_lambda_role.arn
  handler       = local.lambda_handler

  source_code_hash = data.archive_file.email_lambda.output_base64sha256

  runtime = "python3.10"

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.expense.bucket
    }
  }
}

data "archive_file" "processor_lambda" {
  type        = "zip"
  source_dir  = "processor_lambda"
  output_path = "processor_lambda_payload.zip"
}

resource "aws_lambda_function" "processor" {
  filename      = data.archive_file.processor_lambda.output_path
  function_name = "expense_processor"
  role          = aws_iam_role.processor_lambda_role.arn
  handler       = local.lambda_handler

  source_code_hash = data.archive_file.processor_lambda.output_base64sha256

  runtime = "python3.10"
}

# S3 Trigger
resource "aws_lambda_permission" "allow_bucket_email" {
  statement_id  = "AllowExecutionFromS3Bucket-Inbox"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.inbox.arn
}

resource "aws_s3_bucket_notification" "bucket_notification_email" {
  bucket = aws_s3_bucket.inbox.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.email.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket_email]
}

resource "aws_lambda_permission" "allow_bucket_expense" {
  statement_id  = "AllowExecutionFromS3Bucket-Expense"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.expense.arn
}

resource "aws_s3_bucket_notification" "bucket_notification_expense" {
  bucket = aws_s3_bucket.expense.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket_expense]
}

