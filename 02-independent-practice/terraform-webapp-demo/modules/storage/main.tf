resource "random_id" "suffix" {
  byte_length = 4
}


resource "aws_s3_bucket" "this" {
  bucket        = "${var.project}-${var.environment}-${random_id.suffix.hex}"
  force_destroy = var.force_destroy

  tags = {
    Name        = "${var.project}-${var.environment}-bucket"
    Environment = var.environment
  }
}



resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Suspended"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}