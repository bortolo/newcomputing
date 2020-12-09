output "management_vpc_id" {
  description = "The ID of the mgmt VPC"
  value       = module.vpc.vpc_id
}

output "management_public_route_table_ids" {
  description = "The ID of the public route table"
  value       = module.vpc.public_route_table_ids
}

output "management_cidr_block" {
  description = "The cidr block"
  value       = module.vpc.vpc_cidr_block
}

output "EC2_public_ip" {
  description = "The public ip of the mgmt EC2"
  value       = module.ec2_MGMT.public_ip
}
