output "instance_id" {
    value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "ami_used" {
  description = "AMI that was selected automatically"
  value = data.aws_ami.amazon_linux.id
}

