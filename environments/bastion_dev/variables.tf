# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "region" {
  description = "Region in AWS"
  type        = string
  default     = "us-east-1" # N. Virginia (US East)
}

variable "cluster_name" {
  description = "The name to use to namespace all the resources in the cluster"
  type        = string
  default     = "bastion-dev"
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

variable "key_name" {
  description = "Enter your key name"
  type        = string
  default     = "terraform"
}

variable "key_pair" {
  description = "Enter your key pair (public)"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCgQhsY5dUwcXAsFAboeiIc0xmdS5khz52/IwvAD37Ghrtu790lebra4V2uIGlxpwB2znBPY4Qa1ySl/x3rj06dD2In7xYt2Rv/VwHD2FGctd8Dr1MPUxHiajZEQ/lKJhgiqycrXWzPxeJ/DNBjK1svjok5POU3A0oam2t+r7x2xrHW2MIo4Pxo1/Jb2cy9GgfPF6a2EwIMTqH95DYkm872p3hDxTUp48F8cpY2sKW2pUF7RXIKNnA0yj4oOyNXC7CyeuPyhLSRodWfgDJrPjl0Hc2P2K+nDjfdlACS/Mij3XypUfFybtL3AYWMypiLIDprMsbKL2mnJTEdBSCgmT291H66AcnJ95H4LloDISetwFZqmSje27hciuD8R1DQvzz9/GHkstWIE+T7DM7sUMsmLfLauzrqOCUjr5fU6I5IMBr5ZQ76zW2zsQu2RDwb8UIpyN1AgT0eZp7/bGVtPpAYMFzVxNJCvfHGYcXLYR5SacLrfPomym7uX2zrfIbLtjtpn7XUHX+0Pf4F3NMsBORPtMGVf+K6uNqTCHiP5bNwmKK0abvq5hAt06myWA2qA/NSw448lCdsMT8d4/Q1gNYg5EGWejKNHtqxs30B0QjiMs1tZjstNCo0jztfj39azD+F+ERt5ebV8p2lhyPnyqHwd2IkODTywIDyvYnJwnAuSw== aplascencia@nearsoft.com"
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