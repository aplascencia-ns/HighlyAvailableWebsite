# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

# Configure the provider(s)
provider "aws" {
  region = "us-east-1" # N. Virginia (US East)
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  # Input parameters
  cluster_name  = var.cluster_name
  instance_type = "t2.micro"        # poner las variables
  min_size      = 2
  max_size      = 2
}

# Aplicar el state



# resource "aws_security_group_rule" "allow_testing_inbound" {
#   type              = "ingress"
#   security_group_id = module.webserver_cluster.alb_security_group_id

#   from_port   = 12345
#   to_port     = 12345
#   protocol    = "tcp"
#   cidr_blocks = ["0.0.0.0/0"]
# }