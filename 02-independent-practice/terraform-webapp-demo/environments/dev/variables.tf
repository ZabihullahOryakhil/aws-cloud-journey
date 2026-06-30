variable "project" {
  type        = string
  default     = "webapp-demo"
}

variable "environment" {
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "aws_region" {

  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
}

variable "public_subnet_cidrs" {
  type        = list(string)
}

variable "availability_zones" {
  type        = list(string)
}

variable "instance_type" {
  type        = string
}

variable "instance_count" {
  type        = number
}

variable "key_name" {
  type        = string
  default     = ""
}