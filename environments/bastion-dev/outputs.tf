output "alb_dns_name" {
  value       = module.bastion.alb_dns_name
  description = "The domain name of the load balancer"
}
# output "my_ip_ipinfo" {
#   value = ["${data.external.what_is_my_ip.result.ip}/32"]
# }

# output "my_ip_icanhazip" {
#   value = ["${chomp(data.http.myip.body)}/32"]
# }