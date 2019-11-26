# Example of a string variable
variable network_cidr {
  default = "10.0.0.0/16"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "elb_port" {
  description = "The port the ELB will use for HTTP requests"
  type        = number
  default     = 80
}

# Example of a list variable
variable availability_zones {
  default = ["us-east-1a", "us-east-1b"]
}

# Example of an integer variable
# variable instance_count {
#   default = 2
# }

# Example of a map variable
variable ami_ids {
  default = {
    #    "us-west-2" = "ami-0fb83677"
    "us-east-1" = "ami-97785bed"
  }
}

output "nlb_dns_name" {
  value       = aws_lb.web_lb.dns_name
  description = "The domain name of the load balancer"
}