terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = "us-east-2"
  profile = var.profile_name
  default_tags {
    tags = {
      Project        = var.project_name
    }
  }
}

locals {
  ses_to_s3_rule_name = "store_in_s3"
  lambda_handler = "lambda_function.handler"
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
        "${var.project_name}"
      ]
    }
  ]
}
JSON
  }
}

