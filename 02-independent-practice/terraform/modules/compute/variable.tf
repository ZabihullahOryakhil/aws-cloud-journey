variable "environment" {
  type = string
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "bucket_arn" {
  type = string
}