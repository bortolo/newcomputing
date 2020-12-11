output public_ips {
    value = module.ec2.public_ip
    description = "public ip of the instances"
}