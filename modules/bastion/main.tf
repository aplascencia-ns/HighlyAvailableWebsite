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

# Public
data "aws_subnet" "public_subnet_1a" {
  filter {
    name   = "tag:Name"
    values = ["subnet-1a"] # insert value here
  }
}

# Private
data "aws_subnet" "private_subnet_1b" {
  filter {
    name   = "tag:Name"
    values = ["subnet-1b"] # insert value here
  }
}


data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -------------------------------------------
# Get AMI image
# -------------------------------------------
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
  ami                         = "ami-04b9e92b5572fa0d1" # "ami-00068cd7555f543d5" # data.aws_ami.ubuntu_18_04.id # "ami-969ab1f6"
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.bastion_private_sg.id]
  subnet_id                   = data.aws_subnet.private_subnet_1b.id
  associate_public_ip_address = false

  tags = {
    Name = "${var.cluster_name}-private"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# BASTION HOST
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                         = "ami-04b9e92b5572fa0d1" # "ami-00068cd7555f543d5" # data.aws_ami.ubuntu_18_04.id # "ami-969ab1f6"
  key_name                    = aws_key_pair.bastion_key.key_name
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  subnet_id                   = data.aws_subnet.public_subnet_1a.id
  associate_public_ip_address = true

  tags = {
    Name = "${var.cluster_name}-bastion"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "${var.cluster_name}-bastion-sg"
  vpc_id      = data.aws_vpc.default.id
  description = "Enter SG for bastion host. SSH access only"
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_sg.id

  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_sg.id

  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_bastion_private_sg_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_sg.id

  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = aws_security_group.bastion_private_sg.id
}


resource "aws_security_group" "bastion_private_sg" {
  name        = "${var.cluster_name}-bastion-private-sg"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for private instances. SSH inbound requests from Bastion host only."
}

resource "aws_security_group_rule" "allow_bastion_sg_outbound" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion_private_sg.id

  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_all_bastion_private_sg_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.bastion_private_sg.id

  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_key_pair" "bastion_key" {
  key_name   = var.key_name # "id_rsa"
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
  subnet_ids = [data.aws_subnet.private_subnet_1b.id]

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
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = data.aws_subnet.public_subnet_1a.cidr_block    # data.aws_subnet.private_subnet_1b.cidr_block
  from_port   = 22
  to_port     = 22
}

resource "aws_network_acl_rule" "allow_custom_inbound" {
  egress         = false
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 200
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"    # data.aws_subnet.private_subnet_1b.cidr_block
  from_port   = 32768
  to_port     = 65535
}

# Rules OUTBOUND
resource "aws_network_acl_rule" "allow_nacl_HTTP_outbound" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 100
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0" # data.aws_subnet.private_subnet_1b.cidr_block
  from_port   = 80
  to_port     = 80
}

resource "aws_network_acl_rule" "allow_nacl_HTTPS_outbound" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 200
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0" # data.aws_subnet.private_subnet_1b.cidr_block
  from_port   = 443
  to_port     = 443
}

resource "aws_network_acl_rule" "allow_nacl_custom_outbound" {
  egress         = true
  network_acl_id = aws_network_acl.private_nacl.id

  rule_number = 300
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = data.aws_subnet.public_subnet_1a.cidr_block    # data.aws_subnet.private_subnet_1b.cidr_block
  from_port   = 32768
  to_port     = 65535
}


# ############# Route Tables ##########
# PUBLIC Route table: attach Internet Gateway 
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"                          # Destination
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
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id # aws_internet_gateway.main_igw.id # aws_nat_gateway.main_nat_gw.id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

# ********* VALIDAR SI SOLO SE ASOCIA 1 O LAS 2 TODAS PARA EL BASTION ********* #

# ######### PUBLIC Subnet assiosation with rotute table #############
resource "aws_route_table_association" "public_rta" {
  #   count          = 2
  subnet_id      = data.aws_subnet.public_subnet_1a.id # element(aws_subnet.public_subnet.*.id, count.index) 
  route_table_id = aws_route_table.public_rt.id
}

# ########## PRIVATE Subnets assiosation with rotute table #############
resource "aws_route_table_association" "private_rta" {
  #   count          = 2
  subnet_id      = data.aws_subnet.private_subnet_1b.id # element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_rt.id
}



# ########### NAT ##############
# resource "aws_eip" "forNat_eip" {
#   vpc = true

#   tags = {
#     Name = "${var.cluster_name}-eip"
#   }
# }

# resource "aws_nat_gateway" "main_nat_gw" {
# #   count         = 2
#   allocation_id = aws_eip.forNat_eip.id
#   subnet_id = aws_subnet.public_subnet[0].id
# #   subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)
#   depends_on    = [aws_internet_gateway.main_igw]

#   tags = {
#     Name = "${var.cluster_name}-main-nat-gw"
#   }
# }
