output "bucket_name" {
    description = "S3 bucket name"
    value = aws_s3_bucket.app_bucket.id  
}

output "bucket_arn" {
    description = "ARN of the S3 Bucket"
    value = aws_s3_bucket.app_bucket.arn
}

output "bucket_region" {
    description = "Region of the S3 bucket"
    value = aws_s3_bucket.app_bucket.region
  
}