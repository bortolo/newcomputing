output "ec2_public_ipPub" {
  description = "The public IP of the EC2 instance"
  value       = module.ec2_public.public_ip
}

output "ec2_private_ipPrivate" {
  description = "The private IP of the EC2 instance"
  value       = module.ec2_private.private_ip
}
