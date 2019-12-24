# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

# Configure the provider(s)
provider "aws" {
  region = var.region
}

module "webserver_cluster" {
  source = "../../modules/webserver-cluster"

  # Input parameters
  cluster_name          = var.cluster_name
  instance_type         = var.instance_type
  min_size              = var.min_size
  max_size              = var.max_size
  region                = var.region
  ubuntu_account_number = var.ubuntu_account_number
}

# Add State 
terraform {
  backend "s3" {

    # If you wish to run this example manually, uncomment and fill in the config below.
    bucket         = "terraform-state-ns"
    key            = "environments/demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-ns-locks"
    encrypt        = true

  }
}
