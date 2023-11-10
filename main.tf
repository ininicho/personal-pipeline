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


