variable "project" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances behind the ALB."
  type        = number
  default     = 2
}


variable "key_name" {
  type        = string
  default     = ""
}


# Input from networking module
variable "vpc_id" {
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
}

variable "alb_sg_id" {
  type        = string
}

variable "ec2_sg_id" {
  type        = string
}