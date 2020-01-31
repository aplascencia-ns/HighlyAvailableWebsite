# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "region" {
  description = "Region in AWS"
  type        = string
}

variable "environment" {
  description = "The name of environment"
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

# variable "key_name_instance" {
#   description = "Enter your key private instance"
#   type        = string
#   default     = "nearsoft-private-us-east-1-develop"
# }

# variable "key_pair_instance" {
#   description = "Enter your key pair (public)"
#   type        = string
#   default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCdVzdb2xQP3kPQkbntSalb5FDAXYx41GwAD25cVk9XH98MNKlejVgp5JaZ/3DvkHfWS6ZcRIsb7onRmZienmcJIt9kHiLIxPj5MFqNJgtAk1weYrcGOX7PQ+eUoycpCsCv1W/sgQ3CSMDxpMr+1FcNLjMGws1Vb2WQPaJogi7dC7WctsSwbW1RNoCVBgsCz6Y7TH22kS9IzRXfm2SzDbHgMPaYhY6622BZds+HMg3kPA5qjqvgmGtpvHIi/G4iT6OIIFF7du+L/ARj7/J8HuUnT0qoyaqZcWYbgezIQquAHxlcb6sp27yEPx7O4h9QeYrXA8WQn4q/Ja56MSg0yoJUXOGr/P3cO/Lu3Zx6gfAUNNM7048lZYhwe8wn8pU1Ulm8IPoHWSDkDJzDxGwbmxps2i91GX5WXFtKA+l64kkWyAmnU32EpSafKTUm1YIpPw5lZiNFBj8BT1FH0kddgGt967AeHy0Hj4VbwtOpKGpH4E3lfFRGUFYUeupUveb1k2v3kbErlhSHm1yhj9A1jwpAryT3nenRSNoR23wWEn7yWcITiSfeHf3m48PSNNdx3uVlSIwf2rJvu1JleaMGr5hwqDoPEfY5oEJTFykptfKNXMzt9WbSdprqlJHBpfzQ2jQP79pXVXTEv0awqaxclBgGriyPDxRiZfruiXgqyJqLYQ== nearsoft-private-us-east-1-develop"
# }