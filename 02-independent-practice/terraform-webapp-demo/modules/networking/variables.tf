variable "project" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets. One per AZ."
  type        = list(string)
}

variable "availability_zones" {
  description = "AZs to create subnets in."
  type        = list(string)
}