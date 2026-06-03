data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name = "state"
    values = ["available"]
  }
}

resource "aws_security_group" "web" {
  name = "${var.environment}-sg"
  description = "Allow HTTP"
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-sg"}
}


resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action = "sts.AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy" "s3_access" {
  name = "s3-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Action = ["s3.GetObject", "s3:PutObject", "s3.ListBucket"]
        Resource = [var.bucket_arn, "${var.bucket_arn}/*"]
    }]
  })
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "web" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>${var.environment} - built with Terrafrom modlues</h1>" \
    > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.environment}-server"
    Environment = var.environment
  }
}





