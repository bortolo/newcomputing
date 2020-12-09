output "ec2_public_ips" {
  description = "The public IPs of the EC2 instances"
  value       = module.myapp.ec2_public_ips
}

output "ec2_private_ips" {
  description = "The privates IP of the EC2 instances"
  value       = module.myapp.ec2_private_ips
}

// output "elastic_public_ip" {
//   description = "The public ip of the loadbalancer"
//   value       = module.myapp.elastic_public_ip
// }

output "alb_dns" {
  description = "The DNS of the ALB"
  value       = module.myapp.alb_dns
}
