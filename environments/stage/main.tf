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
  source = "../../modules/webserver-cluster"

  # Input parameters
  cluster_name  = var.cluster_name
  instance_type = var.instance_type # "t2.micro"
  min_size      = var.min_size      # 2
  max_size      = var.max_size      # 2
}

# Add State 
terraform {
  backend "s3" {

    # If you wish to run this example manually, uncomment and fill in the config below.
    bucket         = "terraform-state-ns"
    key            = "environments/stage/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-ns-locks"
    encrypt        = true

  }
}




# resource "aws_security_group_rule" "allow_testing_inbound" {
#   type              = "ingress"
#   security_group_id = module.webserver_cluster.alb_security_group_id

#   from_port   = 12345
#   to_port     = 12345
#   protocol    = "tcp"
#   cidr_blocks = ["0.0.0.0/0"]
# }