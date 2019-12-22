variable "cluster_name" {
  description = "The name to use to namespace all the resources in the cluster"
  type        = string
  default     = "BASTION"
}

variable "key_name" {
  description = "Enter your key name"
  type        = string
}

variable "key_pair" {
  description = "Enter your key pair"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
}

variable "region" {
  description = "Region in AWS"
  type        = string
}

variable "ubuntu_account_number" {
  description = "Ubuntu account number"
  type        = string
}
