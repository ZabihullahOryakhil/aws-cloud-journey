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

# VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
      name = "${var.environment}"
      Environment = var.environment
    }
}


# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.subnet_cidr
    availability_zone = "${var.region}"
    map_public_ip_on_launch = true

    tags = {
      Name = "${var.environment}-public-subnet"
    }
}

# Route Table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-rt"
  }
}

resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
  
}

# Security Group
resource "aws_security_group" "web" {
  name = "${var.environment}-sg"
  description = "Allow HTTP"
  vpc_id = aws_vpc.main.id

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

  tags = {
    Name = "${var.environment}-sg"
  }
}



# EC2 Instance
resource "aws_instance" "web" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!bin/bash
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello From Terraform</h1>
    <p>Environment: ${var.environment}. ZABIHULLAH ORYAKHIL</p>" /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.environment}-server"
    Environment = var.environment
  }
}


