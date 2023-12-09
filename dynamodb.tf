# DynamoDB table for Expenses
resource "aws_dynamodb_table" "expenses" {
  name           = "expenses"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"
  range_key      = "date"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }
}

