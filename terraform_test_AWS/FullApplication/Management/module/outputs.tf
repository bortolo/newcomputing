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

output "ec2_id" {
  description = "The id of the EC2 instances to create AMI"
  value       = module.ec2_FE.id[0]
}


output "vpc_id" {
  description = "The ID of the mgmt VPC"
  value       = module.vpc.vpc_id
}

output "public_route_table_ids" {
  description = "The ID of the public route table"
  value       = module.vpc.public_route_table_ids
}

output "cidr_block" {
  description = "The cidr block"
  value       = module.vpc.vpc_cidr_block
}
