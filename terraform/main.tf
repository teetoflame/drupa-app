provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "drupal_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Subnets
resource "aws_subnet" "public_subnets" {
  count = length(var.subnet_cidrs)

  vpc_id                  = aws_vpc.drupal_vpc.id
  cidr_block              = var.subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnets" {
  count = length(var.db_subnet_cidrs)

  vpc_id            = aws_vpc.drupal_vpc.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
}

# Internet Gateway
resource "aws_internet_gateway" "drupal_igw" {
  vpc_id = aws_vpc.drupal_vpc.id
}

# Security Groups
resource "aws_security_group" "drupal_sg" {
  vpc_id = aws_vpc.drupal_vpc.id

  dynamic "ingress" {
    for_each = var.allowed_ingress_ports
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances for Drupal
resource "aws_instance" "drupal_instance" {
  count         = var.min_instance_count
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  key_name      = var.key_name
  subnet_id     = aws_subnet.public_subnets[count.index].id

  vpc_security_group_ids = [aws_security_group.drupal_sg.id]

  root_block_device {
    volume_size = var.ebs_volume_size
  }
}

# RDS Database
resource "aws_db_instance" "drupal_db" {
  allocated_storage      = var.db_allocated_storage
  engine                 = "mysql"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.drupal_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.drupal_db_subnet.name
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "drupal_db_subnet" {
  name       = "drupal-db-subnet"
  subnet_ids = aws_subnet.private_subnets[*].id
}

# Load Balancer
resource "aws_lb" "drupal_alb" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.drupal_sg.id]
  subnets            = aws_subnet.public_subnets[*].id
}

resource "aws_lb_target_group" "drupal_tg" {
  name     = var.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.drupal_vpc.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.drupal_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.drupal_tg.arn
  }

  lifecycle {
    prevent_destroy = false  # Allow Terraform to destroy it when needed
  }
}

resource "aws_lb_target_group" "drupal_tg" {
  name     = var.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.drupal_vpc.id

  lifecycle {
    create_before_destroy = true  # Ensure a new target group is created before deleting the old one
  }
}

# Output Values
output "load_balancer_dns" {
  value = aws_lb.drupal_alb.dns_name
}

output "public_ips" {
  value = aws_instance.drupal_instance[*].public_ip
}
