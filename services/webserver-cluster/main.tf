# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE ALL THE RESOURCES TO DEPLOY AN APP IN AN AUTO SCALING GROUP WITH AN ELB
# This template runs a simple "Hello, World" web server in Auto Scaling Group (ASG) with an Elastic Load Balancer
# (ELB) in front of it to distribute traffic across the EC2 Instances in the ASG.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1" # N. Virginia (US East)
}

# ------------------------------------------------------------------------------
# GET THE LIST OF AVAILABILITY ZONES IN THE CURRENT REGION
# ------------------------------------------------------------------------------

# data "aws_availability_zones" "all" {}


# ---------------------------------------------------------------------------------------------------------------------
#  Create a VPC
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_vpc" "web_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Web VPC"
  }
}

# Add a couple of subnets
# --------------------------------------
resource "aws_subnet" "web_private_subnet" {
  # Use the count meta-parameter to create multiple copies
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.web_vpc.id

  # cidrsubnet function splits a cidr block into subnets
  cidr_block = cidrsubnet(var.network_cidr, 8, count.index) # submask /24 

  # element retrieves a list element at a given index
  availability_zone = element(var.availability_zones, count.index)
  #   availability_zone = element(data.aws_availability_zones.all.names, count.index)

  tags = {
    Name = "Web Private Subnet ${count.index + 1} - ${element(var.availability_zones, count.index)}"
  }
}

# Get subnets
# --------------------------------------
data "aws_subnet_ids" "web_private_subnet" {
  vpc_id = aws_vpc.web_vpc.id
}


resource "aws_security_group" "web_sg" {
  name        = "Web Server Security Group"
  description = "Allow HTTP traffic from ELB security group"
  vpc_id      = aws_vpc.web_vpc.id

  # HTTP access from the VPC
  ingress {
    from_port = var.server_port
    to_port   = var.server_port
    protocol  = "tcp"
    # security_groups = ["aws_security_group.elb_sg.id"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LOAD BALANCING TO ASG
# ---------------------------------------------------------------------------------------------------------------------
# Application Load Balancer
# ----------------
resource "aws_lb" "web_lb" {
  name               = "web-lb-to-asg"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.web_private_subnet.ids   # ["aws_subnet.web_private_subnet.*.id"]
  security_groups    = [aws_security_group.web_lb_sg.id]
  # internal           = true
  # enable_cross_zone_load_balancing = true

  # enable_deletion_protection = true

  # tags = {
  #   Environment = "Web Test"
  # }
}

# Listener
# ----------------
resource "aws_lb_listener" "http_lb_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
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

# Security Group to LB
# ----------------
resource "aws_security_group" "web_lb_sg" {
  name = "web-lb-security-group"

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target Group
# ----------------
resource "aws_lb_target_group" "web_target_asg" {
  name     = "web-target-asg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.web_vpc.id

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


# ---------------------------------------------------------------------------------------------------------------------
# AUTO SCALING GROUP
# ---------------------------------------------------------------------------------------------------------------------
# Launch Configuration
# ----------------
resource "aws_launch_configuration" "web_config_asg" {
  image_id        = lookup(var.ami_ids, "us-east-1") #"ami-97785bed"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # Whenever using a launch configuration with an auto scaling group, you must set create_before_destroy = true.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
# ----------------
resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_config_asg.name
  vpc_zone_identifier  = data.aws_subnet_ids.web_private_subnet.ids

  target_group_arns = [aws_lb_target_group.web_target_asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 3

  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = true
  }
}

# Listener Rule
# ----------------
resource "aws_lb_listener_rule" "web_lister_rule_asg" {
  listener_arn = aws_lb_listener.http_lb_listener.arn
  priority     = 100

  condition {
    field  = "path-pattern"
    values = ["*"]
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target_asg.arn
  }
}


