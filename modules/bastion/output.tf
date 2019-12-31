output "alb_dns_name" {
  value       = aws_lb.bastion_lb.dns_name
  description = "The domain name of the load balancer"
}


# output "bastion_public_ip" {
#   value = aws_instance.bastion_instance.public_ip
# }

# output "vpc_id" {
#   value = data.aws_vpc.default.id
# }

# output "bastion_public_ip" {
#   value = aws_instance.bastion.public_ip
# }

output "my_ip_icanhazip" {
  value = ["${chomp(data.http.myip.body)}/32"]
}
