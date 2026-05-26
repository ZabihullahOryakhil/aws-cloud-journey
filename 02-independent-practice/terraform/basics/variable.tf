variable "environment" {
  description = "Environment Name"
  type = string
  default = "practice"
}

variable "region" {
    description = "AWS Region"
    type = string
    default = "us-east-1"
  
}

variable "bucket_name" {
  description = "S3 bucket name"
  type = string
  default = "terraform-practice-janan-2026"


}