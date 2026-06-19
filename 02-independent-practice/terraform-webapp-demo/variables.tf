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

# AWS Settings
variable "aws_region" {
  type        = string
  default     = "us-east-1"
}


# Networking
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Compute
variable "instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  type        = number
  default     = 2
}

variable "key_name" {
  type        = string
  default     = ""
}