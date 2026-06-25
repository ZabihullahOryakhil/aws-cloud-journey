output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "instance_ids" {
  value = [for i in aws_aws_instance.web : i.id]
}


output "instance_public_ips" {
  value = [for i in awsaws_instance.web : i.public_ip]
}

