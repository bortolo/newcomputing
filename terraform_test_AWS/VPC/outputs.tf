################################################################################
# GETTING STARTED WITH TERRAFORM LANGUAGE
# Terraform uses its own configuration language, designed to allow concise
# descriptions of infrastructure.The Terraform language is declarative,
# describing an intended goal rather than the steps to reach that goal.
# There is just one type of terraform block in this .tf file:
#
# - output; the label immediately after the output keyword is the name of the
#           output (es. "public_instance_ip"). The value argument takes an
#           expression whose result is to be returned to the user
#           (es. module.ec2_public.public_ip). The description argument is a
#           description of the output value that can be customized.
#
################################################################################

output "public_instance_ip" {
  description = "ip of the public instance"
  value       = module.ec2_public.public_ip
}

output "private_instance_ip" {
  description = "ip of the private instance"
  value       = module.ec2_private.public_ip
}

output "database_instance_ip" {
  description = "ip of the database instance"
  value       = module.ec2_database.public_ip
}

output "public_instance_private_ip" {
  description = "private ip of the public instance"
  value       = module.ec2_public.private_ip
}
output "private_instance_private_ip" {
  description = "private ip of the private instance"
  value       = module.ec2_private.private_ip
}
output "database_instance_private_ip" {
  description = "private ip of the database instance"
  value       = module.ec2_database.private_ip
}
