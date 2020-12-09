output "ec2_1_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = module.ec2_1.public_ip
}

output "ec2_1_private_ip" {
  description = "The private IP of the EC2 instance"
  value       = module.ec2_1.private_ip
}

output "ec2_2_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = module.ec2_2.public_ip
}

output "ec2_2_private_ip" {
  description = "The private IP of the EC2 instance"
  value       = module.ec2_2.private_ip
}

output "ec2_3_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = module.ec2_3.public_ip
}

output "ec2_3_private_ip" {
  description = "The private IP of the EC2 instance"
  value       = module.ec2_3.private_ip
}
