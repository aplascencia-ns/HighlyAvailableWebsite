# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

resource "aws_security_group" "instance_sg" {
  name = "${var.cluster_name}-instance-sg" # [Group Name] column in the console
}

resource "aws_security_group_rule" "allow_server_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance_sg.id

  from_port   = var.server_port
  to_port     = var.server_port
  protocol    = local.tcp_protocol # Explicar protocolos
  cidr_blocks = local.all_ips      # Investigar Bastion y VPN. Aplicar Bastion
  # Permitir acceso unico a LB
}

# TODO: Una forma particular de explicar la definición de mi labor como DevOps

# ---------------------------------------------------------------------------------------------------------------------
# AUTO SCALING GROUP
# ---------------------------------------------------------------------------------------------------------------------

# Create a launch configuration, which specifies how to configure each EC2 Instance in the ASG
resource "aws_launch_configuration" "web_asg_lc" {
  image_id        = "ami-04b9e92b5572fa0d1" # Fix with this https://www.terraform.io/docs/providers/aws/d/ami.html
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance_sg.id]
  user_data       = data.template_file.user_data.rendered

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

# The template_file data source renders a template from a template string, which is usually loaded from an external file.
data "template_file" "user_data" {
  # You can use an expression known as a "path reference", which is of the form path
  #     path.module = Returns the filesystem path of the module where the expression is defined
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
  }
}

# create the ASG itself using the aws_autoscaling_group resource
resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_asg_lc.name
  # pull the subnet IDs out of the aws_subnet_ids data source
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  target_group_arns   = [aws_lb_target_group.web_lb_tg.arn]
  health_check_type   = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

# The first step is to create the ALB itself
resource "aws_lb" "web_lb" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.web_lb_sg.id]
}

# The next step is to define a listener for this ALB
# --- Note that, by default, all AWS resources, including ALBs, don’t allow any incoming or outgoing traffic, 
# --- so you need to create a new security group specifically for the ALB
resource "aws_lb_listener" "web_lb_http_lstr" {
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

# You’ll need to tell the aws_lb resource to use this security group via the security_groups
resource "aws_security_group" "web_lb_sg" {
  name = "${var.cluster_name}-alb-sg"
}

# When creating a module, you should always prefer using a separate resource.
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.web_lb_sg.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips # Solamente el acceso de mi IP. Autocalculado con Shell Script
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.web_lb_sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

# you need to create a target group for your ASG
resource "aws_lb_target_group" "web_lb_tg" {
  name     = var.cluster_name
  port     = var.server_port
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

# Finally, it’s time to tie all these pieces together by creating listener rules
resource "aws_lb_listener_rule" "web_lb_lstr_r" {
  listener_arn = aws_lb_listener.web_lb_http_lstr.arn
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

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}


# To get the data out of a data source,
data "aws_vpc" "default" {
  default = true
}

# You can combine this with another data source
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
