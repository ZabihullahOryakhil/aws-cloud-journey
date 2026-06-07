terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = { source = "hashicorp/aws" 
    version = "~> 6.0" }
  }

  backend "s3" {
    bucket         = "tf-state-janan-2026"
    key            = "practice/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_s3_bucket" "app" {
  bucket = "tf-remote-state-app-janan-2026"

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

output "bucket"    { value = aws_s3_bucket.app.id }
output "workspace" { value = terraform.workspace }
