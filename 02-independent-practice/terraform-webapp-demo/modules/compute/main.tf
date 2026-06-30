data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "web" {
  count = var.instance_count

  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = [var.ec2_sg_id]
  key_name = var.key_name != "" ? var.key_name : null


  user_data = <<-EOT
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y nginx

    echo "<h1>Hello from ${var.project}-${var.environment}</h1>
    <p>Instance: $${hostname}</p>
    <p>AZ: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>" \
    > /var/www/html/index.html

    systemctl enable nginx
    systemctl start nginx
  EOT

  tags = {
    Name = "${var.project}-${var.environment}-web-${count.index + 1}"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Application load balancer
resource "aws_lb" "this" {
  name = "${var.project}-${var.environment}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [var.alb_sg_id]
  subnets = var.subnet_ids

  enable_deletion_protection = false
  tags = {
    Name = "${var.project}-${var.environment}-alb"
    Environment = var.environment
  }
}


# Target group
resource "aws_lb_target_group" "this" {
  name = "${var.project}-${var.environment}-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    healthy_threshold = 2
    unhealthy_threshold = 3
    interval = 30
    timeout = 5
    matcher = "200"
  }

  tags = {
    Name = "${var.project}-${var.environment}-tg"
    Environment = var.environment
  }
}


resource "aws_lb_target_group_attachment" "this" {
  count = length(aws_instance.web)

  target_group_arn = aws_lb_target_group.this.arn
  target_id = aws_instance.web[count.index].id
  port = 80
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = {
    Name = "${var.project}-${var.environment}-listener"
    Environment = var.environment
  }
}