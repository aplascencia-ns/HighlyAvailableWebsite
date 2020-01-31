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
  default     = "nearsoft-bastion-us-east-1-develop"
}

variable "key_pair" {
  description = "Enter your key pair (public)"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC4VuURt981IIMa9gkG/v2QvEqhHeRNmxyKOkr1mBXxgZ7UChllr1LThauKnvdUVqc5AN/EA0Xw0DHwEeM1pyNLsTkW7EOlNsH1zwBbQlRg8+O5CxXbqAhaPHC1W1XBLzjI90M/EhjHLjg8l/NUjNK3F5FHlxT5ymdrI8+0WDZ8cVKLUkJXLxkhhNniaIfC5W/3aUqqz8DDadXbrXA445XdRikDC+QngNGu8G8vITdQLd6MutuGltqGWR/2Tlj8T0AwRQHxtYxXIRLPTu5YuBfSAz1Ous1qTIgjSNfdS2mm0tlo5wk2hV876luvMGtHBiMbmKas28oTuARaohKfEcFFbu+5aBkYoLqxifrHSJzH8YOY+dO/o+MboMdQ3cBynBmwIThpCjUJ7bU64SAUzDMvOI2yssfkv4XQqGM8BVsTW/bJYyi9fhAqv1vxxvZdlWH/xCvD7IBxqrVlkUpGuPC3op3slo9BD7f7UgnJixNTo/airizv5bEIac8aEhvfTxCUBRnsL8C36wciPaA7X7D+2ikk3p1cmzDwQtm9CmSAq/J7aqTr6qwH9gwDM6lfeNbhcbpFaAlelioE7x6TfyjnVJyzEAKsXGlzTeLMYBHdO1u/Nt09BLyIJK5oRPlsyFwj/Agb0v0VNL4W45HFWPbU1I14d5NnSfMOHU0XMOITrQ== nearsoft-bastion-us-east-1-develop"
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