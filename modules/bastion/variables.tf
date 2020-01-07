# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "region" {
  description = "Region in AWS"
  type        = string
}

variable "cluster_name" {
  description = "The name to use to namespace all the resources in the cluster"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

variable "ubuntu_account_number" {
  description = "Ubuntu account number"
  type        = string
}

variable "key_name" {
  description = "Enter your key name"
  type        = string
}

variable "key_pair" {
  description = "Enter your key pair"
  type        = string
}

variable "key_name_instance" {
  description = "Enter your key private instance"
  type        = string
}

variable "key_pair_instance" {
  description = "Enter your key pair (public)"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}