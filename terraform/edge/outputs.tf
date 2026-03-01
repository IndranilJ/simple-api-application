output "lb_ip" {
  description = "Public IP of the Global Load Balancer. Access the app at http://[lb_ip]"
  value       = module.load_balancer.ip_address
}
