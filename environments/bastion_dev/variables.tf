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
  default     = "angel_nearsoft"
}

variable "key_pair" {
  description = "Enter your key pair (public)"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC4VuURt981IIMa9gkG/v2QvEqhHeRNmxyKOkr1mBXxgZ7UChllr1LThauKnvdUVqc5AN/EA0Xw0DHwEeM1pyNLsTkW7EOlNsH1zwBbQlRg8+O5CxXbqAhaPHC1W1XBLzjI90M/EhjHLjg8l/NUjNK3F5FHlxT5ymdrI8+0WDZ8cVKLUkJXLxkhhNniaIfC5W/3aUqqz8DDadXbrXA445XdRikDC+QngNGu8G8vITdQLd6MutuGltqGWR/2Tlj8T0AwRQHxtYxXIRLPTu5YuBfSAz1Ous1qTIgjSNfdS2mm0tlo5wk2hV876luvMGtHBiMbmKas28oTuARaohKfEcFFbu+5aBkYoLqxifrHSJzH8YOY+dO/o+MboMdQ3cBynBmwIThpCjUJ7bU64SAUzDMvOI2yssfkv4XQqGM8BVsTW/bJYyi9fhAqv1vxxvZdlWH/xCvD7IBxqrVlkUpGuPC3op3slo9BD7f7UgnJixNTo/airizv5bEIac8aEhvfTxCUBRnsL8C36wciPaA7X7D+2ikk3p1cmzDwQtm9CmSAq/J7aqTr6qwH9gwDM6lfeNbhcbpFaAlelioE7x6TfyjnVJyzEAKsXGlzTeLMYBHdO1u/Nt09BLyIJK5oRPlsyFwj/Agb0v0VNL4W45HFWPbU1I14d5NnSfMOHU0XMOITrQ== angel_nearsoft"
}

# variable "key_name_instance" {
#   description = "Enter your key private instance"
#   type        = string
#   default     = "private_instance"
# }

# variable "key_pair_instance" {
#   description = "Enter your key pair (public)"
#   type        = string
#   default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDcs8txNPxsuaagpID4QJXWCT+chzCtydZKw3yRsKVFopQV2UHm/pvqjZUzQtaToYgppSp3CD4hG986yBumDlTNyg4mf7nwcHK/J5TASHOcMvReK7gq+ocT84mod+m1uyRIlXMNBZpcEjaO+PBWdx5wbbHw86V2e9VgHPyM+119x4lNWuML2WvQQ1lEpa88FUzQVTiL3L4kA2+kqCWTkCku7g9i794M7j8m/AkMTEb9VJymV82F0r4YL/M/AFUnUu3F8K7lCna9AG34gzQvlJysL9SvdlypCqliKC2kkoAcyHfyVsfvfwbEk7ErlMuL5Ixw8FDEdVwe4AY4YXPES5YBm86cfIA8KOLEuHDsP0K9799YlSsvk1JvOc/E1cuk/jV1/xz1/APjWm0+TlBJwyaKyqsiDd0DkVxHuRh8i61AxEGhHQm8gu+Dqpw+FktNwABv7PTWtub9zNECasX3qcQhkKauKGqVKpCV3mjVufWy6mKz10FbdtvhU2WbLZ+N7+rzAnu04QSXM4F9Vf5liZffhYTxpqGd/jvUcs1T/4aeJ3ZQD/PKEDwMX9J9Nbic/kbjGjjXc6qjhGFqkJVyzPIXQSWIKt/XNKKjzcWgm6oVUbBRBIPq3VvXmrJr32HyrrZHZ0ngrWnFzUdj3mO8JVExsUnXYnE/GnMMPnBi0JlgaQ== private_instance"
# }

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}