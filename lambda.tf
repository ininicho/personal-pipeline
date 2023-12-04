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

# Cloudwatch Group
resource "aws_cloudwatch_log_group" "email_processor" {
  name              = "/aws/lambda/${aws_lambda_function.email_processor.function_name}"
  retention_in_days = 7
}

# Lambda Payload
data "archive_file" "email_lambda" {
  type        = "zip"
  source_dir  = "email_lambda"
  output_path = "email_lamba_payload.zip"
}

resource "aws_lambda_function" "email_processor" {
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

# S3 Trigger
resource "aws_lambda_permission" "allow_bucket_email" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.inbox.arn
}

resource "aws_s3_bucket_notification" "bucket_notification_email" {
  bucket = aws_s3_bucket.inbox.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.email_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket_email]
}

