# AWS General Settings
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]
}

# VPC and Networking
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "List of public subnet CIDRs for EC2 instances"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "db_subnet_cidrs" {
  description = "List of private subnet CIDRs for RDS"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Security Groups
variable "allowed_ingress_ports" {
  description = "List of allowed ingress ports for EC2"
  type        = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },     
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },    
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 5050, to_port = 5050, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

variable "alb_ingress_ports" {
  description = "Allowed ALB ingress traffic"
  type        = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },     
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

# EC2 Instances
variable "ec2_instance_type" {
  description = "Instance type for Drupal application servers"
  type        = string
  default     = "t3.medium"
}

variable "ec2_ami" {
  description = "AMI ID for Ubuntu 22.04"
  type        = string
  default     = "ami-0c1ac8a41498c1a9c" 
}

variable "key_name" {
  description = "Name of the existing key pair for SSH access"
  type        = string
  default     = "bincom"
}

variable "ebs_volume_size" {
  description = "Size of the EBS volume attached to the EC2 instance in GB"
  type        = number
  default     = 50
}

# Auto Scaling
variable "min_instance_count" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

variable "max_instance_count" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 4
}

# RDS MySQL Database
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Storage size for the database (in GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "drupaldb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "yourpassword"
}

# Load Balancer
variable "lb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "drupal-lb"
}

variable "target_group_name" {
  description = "Name of the target group for ALB"
  type        = string
  default     = "drupal-tg"
}
