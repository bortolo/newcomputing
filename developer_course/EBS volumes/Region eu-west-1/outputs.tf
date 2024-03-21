output public_ips {
    value = module.webserver.public_ip
    description = "public ip of the instances"
}

output ebs_volume {
    value = data.aws_ebs_volume.ebs_volume.id
    description = "Id of the EBS volume selected"
}

output ec2_block_device{
    value = module.webserver.ebs_block_device[*].volume_id
    description = "lista dei block device EC2"
}
