/*output "cluster_instance_ip" {
  description = "ip of the cluster instance"
  value       = module.ec2_cluster.public_ip
}*/
output "spread_instance_ip" {
  description = "ip of the spread instance"
  value       = module.ec2_spread.public_ip
}

/*output "cluster_instance_private_ip" {
  description = "private ip of the cluster instance"
  value       = module.ec2_cluster.private_ip
}*/
output "spread_instance_private_ip" {
  description = "private ip of the spread instance"
  value       = module.ec2_spread.private_ip
}
