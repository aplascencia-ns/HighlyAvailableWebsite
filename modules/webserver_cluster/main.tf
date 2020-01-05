# Require a specific Terraform version or higher
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

# Configure the provider(s)
provider "aws" {
  region = "us-east-1" # N. Virginia (US East)
}

################
# Data Sources
################
data "aws_availability_zones" "available" {}

# Main VPC
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["main_vpc"]
  }
}

# Public Subnets
data "aws_subnet" "public_1a" {
  filter {
    name   = "tag:Name"
    values = ["main_public_1a"]
  }
}

data "aws_subnet" "public_1b" {
  filter {
    name   = "tag:Name"
    values = ["main_public_1b"]
  }
}

# Privates Subnets
data "aws_subnet" "private_1a" {
  filter {
    name   = "tag:Name"
    values = ["main_private_1a"]
  }
}

data "aws_subnet" "private_1b" {
  filter {
    name   = "tag:Name"
    values = ["main_private_1b"]
  }
}

# Internet Gateway
data "aws_internet_gateway" "main" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Getting what is my ip
data "external" "what_is_my_ip" {
  program = ["bash", "-c", "curl -s 'https://ipinfo.io/json'"]
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}


# Get AMI image
data "aws_ami" "ubuntu_18_04" {
  most_recent = true
  owners      = [var.ubuntu_account_number]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

##################
# Security Groups
##################
#
# For Instances
resource "aws_security_group" "instance_sg" {
  name        = "${var.cluster_name}_instance_sg" # [Group Name] column in the console
  description = "Enter SG for instances. HTTP access and Port 8080 access only."
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group_rule" "allow_server_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance_sg.id

  from_port                = var.server_port
  to_port                  = var.server_port
  protocol                 = local.tcp_protocol
  source_security_group_id = aws_security_group.web_lb_sg.id # <-- Permitir acceso unico a LB
}

#
# For Load Balancer
resource "aws_security_group" "web_lb_sg" {
  name        = "${var.cluster_name}_lb_sg"
  description = "Enter SG for Load Balancer. HTTP access only."
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.web_lb_sg.id

  protocol    = local.tcp_protocol
  from_port   = local.http_port # 80
  to_port     = local.http_port
  cidr_blocks = local.all_ips_list
  # cidr_blocks = ["${chomp(data.http.myip.body)}/32"] # chomp() --> removes newline characters at the end of a string.
  # cidr_blocks = ["${data.external.what_is_my_ip.result.ip}/32"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.web_lb_sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

# TODO: Una forma particular de explicar la definición de mi labor como DevOps

###########################
# Auto Scaling Group (ASG)
###########################
# Create a launch configuration, which specifies how to configure each EC2 Instance in the ASG
resource "aws_launch_configuration" "web_asg_lc" {
  # "ami-04b9e92b5572fa0d1" --> Ubuntu 18.04 Free Tier
  # "ami-00068cd7555f543d5" --> Amazon Linux 2 Free Tier   
  image_id        = data.aws_ami.ubuntu_18_04.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance_sg.id]
  user_data       = data.template_file.user_data.rendered

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

# create the ASG itself using the aws_autoscaling_group resource
resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_asg_lc.name
  vpc_zone_identifier  = [data.aws_subnet.private_1a.id, data.aws_subnet.private_1b.id]
  target_group_arns    = [aws_lb_target_group.web_lb_tg.arn]
  health_check_type    = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

# The template_file data source renders a template from a template string, which is usually loaded from an external file.
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
  }
}

################
# Load Balancer
################
# The first step is to create the ALB itself
resource "aws_lb" "web_lb" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = [data.aws_subnet.public_1a.id, data.aws_subnet.public_1b.id]
  security_groups    = [aws_security_group.web_lb_sg.id]
}

############
# Listeners
############
# The next step is to define a listener for this ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = local.http_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

################
# Rules for ASG
################
# Finally, it’s time to tie all these pieces together by creating listener rules
resource "aws_lb_listener_rule" "web_lb_lstr_r" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_lb_tg.arn
  }
}

#######################
# Target Group for ASG
#######################
# you need to create a target group for your ASG
resource "aws_lb_target_group" "web_lb_tg" {
  name     = var.cluster_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

locals {
  http_port       = 80
  any_port        = 0
  any_protocol    = "-1"
  tcp_protocol    = "tcp"
  all_ips         = ["0.0.0.0/0"]
  all_ips_list    = ["0.0.0.0/0"]
  my_ip_icanhazip = ["${data.external.what_is_my_ip.result.ip}/32"]
  my_ip_ipinfo    = ["${chomp(data.http.myip.body)}/32"] # chomp() --> removes newline characters at the end of a string.
}
