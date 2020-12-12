################################################################################
# GETTING STARTED WITH TERRAFORM LANGUAGE
# Terraform uses its own configuration language, designed to allow concise
# descriptions of infrastructure.The Terraform language is declarative,
# describing an intended goal rather than the steps to reach that goal.
# There is just one type of terraform block in this .tf file:
#
# - output; the label immediately after the output keyword is the name of the
#           output (es. "public_ips"). The value argument takes an
#           expression whose result is to be returned to the user
#           (es. module.ec2.public_ip). The description argument is a
#           description of the output value that can be customized.
#
################################################################################

output public_ips {
    value = module.ec2.public_ip
    description = "public ip of the instances"
}