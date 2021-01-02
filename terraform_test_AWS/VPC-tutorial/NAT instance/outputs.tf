output "ec2_public_a" {
  description = "The public IP of the EC2 instance"
  value       = module.ec2_public_a.public_ip
}
