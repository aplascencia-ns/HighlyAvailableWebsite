# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

# Configure the provider(s)
provider "aws" {
  region = "us-east-1" # N. Virginia (US East)
}

# ---------------------------------------------------------------------------------------------------------------------
#  Get DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------
data "aws_availability_zones" "available" {}


data "aws_vpc" "default" {
  default = true
}

# ------------------------
# Subnets
# ------------------------
# Publics
data "aws_subnet" "public_subnet_1a" {
  filter {
    name   = "tag:Name"
    values = ["subnet-1a"] # insert value here
  }
}

data "aws_subnet" "public_subnet_1d" {
  filter {
    name   = "tag:Name"
    values = ["subnet-1d"] # insert value here
  }
}

# Privates
data "aws_subnet" "private_subnet_1b" {
  filter {
    name   = "tag:Name"
    values = ["subnet-1b"] # insert value here
  }
}

data "aws_subnet" "private_subnet_1c" {
  filter {
    name   = "tag:Name"
    values = ["subnet-1c"] # insert value here
  }
}

# ------------------------
# Internet Gateway
# ------------------------
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ------------------------
# Getting what is my ip
# ------------------------
data "external" "what_is_my_ip" {
  program = ["bash", "-c", "curl -s 'https://ipinfo.io/json'"]
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}


# ------------------------
# Get AMI image
# ------------------------
data "aws_ami" "ubuntu_18_04" {
  most_recent = true
  owners      = [var.ubuntu_account_number]

  # Si es FREE TIER? 
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

# PRIVATE INSTANCE
resource "aws_instance" "private_instance" {
    # "ami-04b9e92b5572fa0d1" --> Ubuntu 18.04 Free Tier
    # "ami-00068cd7555f543d5" --> Amazon Linux 2 Free Tier   
  ami                         = data.aws_ami.ubuntu_18_04.id # "ami-969ab1f6"
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.bastion_private_sg.id]
  subnet_id                   = data.aws_subnet.private_subnet_1b.id
  key_name                    = aws_key_pair.bastion_key.key_name
  associate_public_ip_address = false

  tags = {
    Name = "${var.cluster_name}-private"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AUTO SCALING GROUP
# ---------------------------------------------------------------------------------------------------------------------
# Create a launch configuration, which specifies how to configure each EC2 Instance in the ASG
resource "aws_launch_configuration" "bastion_asg_lc" {
  image_id        = data.aws_ami.ubuntu_18_04.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.bastion_sg.id]
  user_data       = data.template_file.user_data.rendered
  key_name        = aws_key_pair.bastion_key.key_name

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
resource "aws_autoscaling_group" "bastion_asg" {
  launch_configuration = aws_launch_configuration.bastion_asg_lc.name
  vpc_zone_identifier  = [data.aws_subnet.public_subnet_1a.id, data.aws_subnet.public_subnet_1d.id]
  target_group_arns    = [aws_lb_target_group.bastion_lb_tg.arn]
  health_check_type    = "ELB"

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
resource "aws_lb" "bastion_lb" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = [data.aws_subnet.public_subnet_1a.id, data.aws_subnet.public_subnet_1d.id]
  security_groups    = [aws_security_group.bastion_lb_sg.id]
}

# The next step is to define a listener for this ALB
resource "aws_lb_listener" "bastion_lb_http_lstr" {
  load_balancer_arn = aws_lb.bastion_lb.arn
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
resource "aws_security_group" "bastion_lb_sg" {
  name = "${var.cluster_name}-alb-sg"
}

# When creating a module, you should always prefer using a separate resource.
resource "aws_security_group_rule" "allow_http_inbound_bastion_lb_sg" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_lb_sg.id

  from_port   = local.http_port # 80
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips_list
  # cidr_blocks = local.my_ip_icanhazip # Solamente el acceso de mi IP.
  # cidr_blocks = local.my_ip_ipinfo
}

resource "aws_security_group_rule" "allow_all_outbound_bastion_lb_sg" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_lb_sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips_list
}

# you need to create a target group for your ASG
resource "aws_lb_target_group" "bastion_lb_tg" {
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
resource "aws_lb_listener_rule" "bastion_lb_lstr_r" {
  listener_arn = aws_lb_listener.bastion_lb_http_lstr.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bastion_lb_tg.arn
  }
}




# # ---------------------------------------------------------------------------------------------------------------------
# # BASTION HOST
# # ---------------------------------------------------------------------------------------------------------------------
# # TODO: Agregar ASG. Levantar 2 servers
# resource "aws_instance" "bastion_instance" {
#   ami                         = data.aws_ami.ubuntu_18_04.id  #"ami-04b9e92b5572fa0d1" # "ami-00068cd7555f543d5"  # "ami-969ab1f6"
#   key_name                    = aws_key_pair.bastion_key.key_name
#   instance_type               = var.instance_type
#   vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
#   subnet_id                   = data.aws_subnet.public_subnet_1a.id
#   associate_public_ip_address = true

#   tags = {
#     Name = "${var.cluster_name}-bastion"
#   }
# }

# ---------------------------------------------------------------------------------------------------------------------
# Security Group for bastion
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "bastion_sg" {
  name        = "${var.cluster_name}-bastion-sg"
  vpc_id      = data.aws_vpc.default.id
  description = "Enter SG for bastion host. SSH access only"
}

resource "aws_security_group_rule" "allow_server_http_inbound_bastion_sg" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_sg.id

  from_port                = var.server_port # 8080
  to_port                  = var.server_port
  protocol                 = local.tcp_protocol
  source_security_group_id = aws_security_group.bastion_lb_sg.id # <-- Permitir acceso unico a LB
  # cidr_blocks = local.all_ips
}


resource "aws_security_group_rule" "allow_ssh_inbound_bastion_sg" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_sg.id

  protocol    = local.tcp_protocol
  from_port   = local.ssh_port
  to_port     = local.ssh_port
  cidr_blocks = local.all_ips_list
  # cidr_blocks = ["${chomp(data.http.myip.body)}/32"] # chomp() --> removes newline characters at the end of a string.
  # cidr_blocks = ["${data.external.what_is_my_ip.result.ip}/32"]
}

resource "aws_security_group_rule" "allow_all_outbound_bastion_sg" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_sg.id

  protocol    = local.any_protocol
  from_port   = local.any_port
  to_port     = local.any_port
  cidr_blocks = local.all_ips_list
}

resource "aws_security_group_rule" "allow_bastion_private_sg_outbound_bastion_sg" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_sg.id

  protocol                 = local.tcp_protocol
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  source_security_group_id = aws_security_group.bastion_private_sg.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Security Group for Private instances
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "bastion_private_sg" {
  name        = "${var.cluster_name}-bastion-private-sg"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for private instances. SSH inbound requests from Bastion host only."
}

resource "aws_security_group_rule" "allow_bastion_sg_outbound_bastion_private_sg" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_private_sg.id

  protocol                 = local.tcp_protocol
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_all_outbound_bastion_private_sg" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_private_sg.id

  protocol    = local.any_protocol
  from_port   = local.any_port
  to_port     = local.any_port
  cidr_blocks = local.all_ips_list
}

resource "aws_key_pair" "bastion_key" {
  key_name   = var.key_name
  public_key = var.key_pair
}

# ---------------------------------------------------------------------------------------------------------------------
#  NETWORKING
# ---------------------------------------------------------------------------------------------------------------------
############# Internet Gateway #############
# resource "aws_internet_gateway" "main_igw" {
#   vpc_id = data.aws_vpc.default.id

#   tags = {
#     Name = "${var.cluster_name}-main-igw"
#   }
# }

# ########### NACL ##############
resource "aws_network_acl" "private_nacl" {
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = [data.aws_subnet.private_subnet_1b.id, data.aws_subnet.private_subnet_1c.id]

  tags = {
    Name = "${var.cluster_name}-private-NACL"
  }
}

# Adding Rules to a Private Network ACL
# Rules INBOUND
resource "aws_network_acl_rule" "allow_ssh_inbound" {
  egress         = false
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 100
  protocol    = local.tcp_protocol
  rule_action = "allow"
  cidr_block  = data.aws_subnet.public_subnet_1a.cidr_block
  from_port   = local.ssh_port
  to_port     = local.ssh_port
}

# REVIEW IT
resource "aws_network_acl_rule" "allow_ssh_inbound_1d" {
  egress         = false
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 101
  protocol    = local.tcp_protocol
  rule_action = "allow"
  cidr_block  = data.aws_subnet.public_subnet_1d.cidr_block
  from_port   = local.ssh_port
  to_port     = local.ssh_port
}


resource "aws_network_acl_rule" "allow_custom_inbound" {
  egress         = false
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 200
  protocol    = local.tcp_protocol
  rule_action = "allow"
  cidr_block  = local.all_ips
  from_port   = 32768
  to_port     = 65535
}

# Rules OUTBOUND
resource "aws_network_acl_rule" "allow_nacl_http_outbound" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 100
  protocol    = local.tcp_protocol
  rule_action = "allow"
  cidr_block  = local.all_ips
  from_port   = local.http_port
  to_port     = local.http_port
}

resource "aws_network_acl_rule" "allow_nacl_https_outbound" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 200
  protocol    = local.tcp_protocol
  rule_action = "allow"
  cidr_block  = local.all_ips
  from_port   = local.https_port
  to_port     = local.https_port
}

resource "aws_network_acl_rule" "allow_nacl_custom_outbound" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 300
  protocol    = local.tcp_protocol
  rule_action = "allow"
  cidr_block  = data.aws_subnet.public_subnet_1a.cidr_block
  from_port   = 32768
  to_port     = 65535
}

# REVIEW IT 
resource "aws_network_acl_rule" "allow_nacl_custom_outbound_1d" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 301
  protocol    = local.tcp_protocol
  rule_action = "allow"
  cidr_block  = data.aws_subnet.public_subnet_1d.cidr_block
  from_port   = 32768
  to_port     = 65535
}



# ############# Route Tables ##########
# PUBLIC Route table: attach Internet Gateway 
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = local.all_ips                        # Destination
    gateway_id = data.aws_internet_gateway.default.id # aws_internet_gateway.main_igw.id # Target
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

# PRIVATE Route table: 
resource "aws_route_table" "private_rt" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = local.all_ips
    gateway_id = data.aws_internet_gateway.default.id # aws_internet_gateway.main_igw.id # aws_nat_gateway.main_nat_gw.id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

# ######### PUBLIC Subnet assiosation with rotute table #############
resource "aws_route_table_association" "public_rta" {
  subnet_id      = data.aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_1d_rta" {
  subnet_id      = data.aws_subnet.public_subnet_1d.id
  route_table_id = aws_route_table.public_rt.id
}


# ########## PRIVATE Subnets assiosation with rotute table #############
resource "aws_route_table_association" "private_rta" {
  subnet_id      = data.aws_subnet.private_subnet_1b.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_1c_rta" {
  subnet_id      = data.aws_subnet.private_subnet_1c.id
  route_table_id = aws_route_table.private_rt.id
}


locals {
  http_port       = 80
  https_port      = 443
  ssh_port        = 22
  any_port        = 0
  any_protocol    = -1
  tcp_protocol    = "tcp"
  all_ips         = "0.0.0.0/0"
  all_ips_list    = ["0.0.0.0/0"]
  my_ip_icanhazip = ["${data.external.what_is_my_ip.result.ip}/32"]
  my_ip_ipinfo    = ["${chomp(data.http.myip.body)}/32"] # chomp() --> removes newline characters at the end of a string.
}
