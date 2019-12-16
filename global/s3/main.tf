terraform {
  required_version = ">= 0.12"
}

# Configure our AWS connection
provider "aws" {
  region = "us-east-1" # N. Virginia (US East)
}

# ---------------------------------------------------------------------------------------------------------------------
# To make this work, you had to use a two-step process:
#   1. Write Terraform code to create the S3 bucket and DynamoDB table and deploy that code with a local backend.
#   2. Go back to the Terraform code, add a remote backend configuration to it to use the newly created S3 bucket 
#      and DynamoDB table, and run terraform init to copy your local state to S3.
# ---------------------------------------------------------------------------------------------------------------------
# ------------------
# STEP [1]
# ------------------
# S3
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  // This is only here so we can destroy the bucket as part of automated tests. You should not copy this for production
  // usage
  force_destroy = true

  # Prevent accidental deletion of this S3 bucket
  # lifecycle {
  #   prevent_destroy = true # false
  # }

  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


# DynamoDB
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ------------------
# STEP [2]
# ------------------
# # Add Backend configuration
# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-ns"
#     key            = "global/s3/terraform.tfstate"
#     region         = "us-east-1"

#     dynamodb_table = var.table_name # "terraform-state-ns-locks"
#     encrypt        = true
#   }
# }




# ---------------------------------------------------------------------------------------------------------------------
# If you ever WANTED TO DELETE the S3 bucket and DynamoDB table you’d have to do this two-step process in reverse
#   1. Go to the Terraform code, remove the backend configuration, and rerun terraform init to copy the Terraform state back to your local disk.
#   2. Run terraform destroy to delete the S3 bucket and DynamoDB table.
# ---------------------------------------------------------------------------------------------------------------------

# # Outputs
# output "s3_bucket_arn" {
#   value       = aws_s3_bucket.terraform_state.arn
#   description = "The ARN of the S3 bucket"
# }

# output "dynamodb_table_name" {
#   value       = aws_dynamodb_table.terraform_locks.name
#   description = "The name of the DynamoDB table"
# }