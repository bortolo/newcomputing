output "ec2_public_ips" {
  description = "The public IPs of the EC2 instances"
  value       = module.ec2_FE.public_ip
}

output "ec2_private_ips" {
  description = "The privates IP of the EC2 instances"
  value       = module.ec2_FE.private_ip
}

output "elastic_public_ip" {
  description = "The public ip of the loadbalancer"
  value       = aws_eip.lb.*.public_ip
}
