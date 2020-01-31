terraform {
  required_version = ">= 0.12"
}

# Configure the provider(s)
provider "aws" {
  region = "us-east-1" # N. Virginia (US East)
}

data "aws_vpc" "default" {
  default = "true"
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
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


resource "aws_security_group" "wordpress_sg" {
  name        = "${var.environment}-${var.cluster_name}-sg"
  vpc_id      = data.aws_vpc.default.id
  description = "Enter SG for bastion host. SSH access only"
}


resource "aws_security_group_rule" "allow_server_http_inbound_wordpress_sg" {
  type              = "ingress"
  security_group_id = aws_security_group.wordpress_sg.id

  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.wordpress_alb_sg.id # <-- Permitir acceso unico a LB
}

resource "aws_security_group_rule" "allow_ssh_inbound_wordpress_sg" {
  type              = "ingress"
  security_group_id = aws_security_group.wordpress_sg.id

  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound_wordpress_sg" {
  type              = "egress"
  security_group_id = aws_security_group.wordpress_sg.id

  protocol    = "tcp"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "wordpress_alb_sg" {
  name        = "${var.environment}-${var.cluster_name}-wp-alb-sg"
  description = "Allow trafic from ALB to wordpress nodes"
  vpc_id      = data.aws_vpc.default.id


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port   = 80
    to_port     = 80 #***
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-wp-alb-sg"
    Environment = "${var.environment}"
  }
}


resource "aws_launch_configuration" "wordpress_asg_lc" {
  image_id      = "ami-04b9e92b5572fa0d1" # data.aws_ami.ubuntu_18_04.id
  instance_type = var.instance_type
  security_groups = [
    aws_security_group.wordpress_sg.id,
    aws_security_group.allow_trafic_public_nodes.id
  ]
  user_data = data.template_file.user_data.rendered
  key_name  = aws_key_pair.wordpress_key.key_name

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "wordpress_asg" {
  launch_configuration = aws_launch_configuration.wordpress_asg_lc.name
  vpc_zone_identifier  = [sort(data.aws_subnet_ids.default.ids)[0], sort(data.aws_subnet_ids.default.ids)[1]]
  target_group_arns    = [aws_lb_target_group.wordpress_alb_tg.arn]
  health_check_type    = "EC2"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "allow_trafic_public_nodes" {
  name        = "${var.environment}-${var.cluster_name}-alb-instance"
  description = "Allow ALB trafic to nodes"

  vpc_id = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Nginx HTTP node port"
    from_port       = "80"
    to_port         = "80"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.wordpress_alb_sg.id}"]
  }

}


################
# Load Balancer
################
# The first step is to create the ALB itself
resource "aws_lb" "wordpress_alb" {
  name               = "${var.environment}-${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets         = [sort(data.aws_subnet_ids.default.ids)[0], sort(data.aws_subnet_ids.default.ids)[1]]
  security_groups = [aws_security_group.wordpress_alb_sg.id]
}

############
# Listeners
############
# The next step is to define a listener for this ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "80" #local.http_port
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
resource "aws_lb_listener_rule" "wordpress_alb_lstr_r" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_alb_tg.arn
  }
}

#######################
# Target Group for ASG
#######################
# you need to create a target group for your ASG
resource "aws_lb_target_group" "wordpress_alb_tg" {
  name     = "${var.environment}-${var.cluster_name}-alb-tg"
  port     = "8080" # var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

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


data "template_file" "user_data" {
  template = "${file("${path.module}/files/config/bootstrap.tpl")}"

  vars = {
    dbhost = "localhost" #"${aws_db_instance.wpdb.address}"
  }
}



resource "aws_key_pair" "wordpress_key" {
  key_name   = "wordpress"
  public_key = file("${path.module}/files/private/nearsoft-wordpress-us-east-1-develop-rsa.pub")
}


locals {
  http_port    = 80
  https_port   = 443
  ssh_port     = 22
  any_port     = 0
  any_protocol = -1
  tcp_protocol = "tcp"
  all_ips      = "0.0.0.0/0"
  all_ips_list = ["0.0.0.0/0"]
}
