# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "region" {
  description = "Region in AWS"
  type        = string
  default     = "us-east-1" # N. Virginia (US East)
}

variable "cluster_name" {
  description = "The name to use to namespace all the resources in the cluster"
  type        = string
  default     = "webservers-develop"
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
  default     = 1
}

variable "ubuntu_account_number" {
  description = "Ubuntu account number"
  type        = string
  default     = "099720109477" # Canonical
}

variable "key_name_instance" {
  description = "Enter your key private instance"
  type        = string
  default     = "develop_instance"
}

variable "key_pair_instance" {
  description = "Enter your key pair (public)"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCaQVq7V6gdsn+HEnNBIZolEPuUPEEWyTk3VAgJvvMvhJRq9lq+jm4DVLTy70ugYwgjIhSxd1Bqf29/ST3+O3tBDPeXh6DbwrnkDwC1EGTIbt3ksBTmzyUF/bWOil4TuO+8C89WFdnFm+a6Bpb0Q+zlvy9l8iouoH1OOg4FSXwt3CmjW4r3itE2o3qwYPkY6+7sgRGwPQURJgju4r5yFqDdRj7SsXOi8vNmFuaCgZbpze1yz6t+3EVUX+sjlk4+/nZCYZ9KLgHUmCVNY1AT2m2kf50fb4rGpBaNdqME2hxUCbBhyviME94mKyhE33Y6JW8QmzSKCEs+YN6XY1JdLHuoVmNRYDLf9LApjtuvSbJbQizcJmt+kdUPU3VctwXUMIiaHPf7eYJtjzo6Czlhy/msw5Nqe3/Ew78AXp8ZbtvpIuxpzRodRzOAM6v49rzXKpAWDAa99ZKbsTme175OmZbP9+jO/+XY5YZWG9Ma5UTtptCkzEadCFTgXKF9Mph/vScgcvZOMLN1NHdfojfFpCaY1B7Sh2Q7nQPRmCb8p5eNRIuPV2gBIB2/hFxWAR+br64Noan4G26Xha2vONjAnfZqHDrQxH4Avnn9Q/PwwtH60eu+T/8buDNjr84WXA0ML8teM9qt35zpZgYng/d2r2s67LnsVKdCFTtR8aEDdUsjjw== develop_instance"
}