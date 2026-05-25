terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "my_bucket" {
  bucket        = var.bucket_name
  force_destroy = true          # ← add this line

  tags = {
    Name        = var.bucket_name
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}