provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "EBS"
  }
  ec2_tag_public         = { server_type = "public" }
  security_group_tag_ec2 = { scope = "security_server" }
}


################################################################################
# standard EBS (read: 1484 IOPS / write: 1484 IOPS)
################################################################################
resource "aws_ebs_volume" "standard" {
  availability_zone = "eu-central-1a"
  size              = 16
  type              = "standard"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_standard" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.standard.id
  instance_id = module.ec2_public.id[0]
}

################################################################################
# gp2 EBS
# t2.micro (read: 1543 IOPS / write: 1542 IOPS)
# i3.large (read: 1542 IOPS / write: 1542 IOPS)
################################################################################
resource "aws_ebs_volume" "gp2" {
  availability_zone = "eu-central-1a"
  size              = 16
  type              = "gp2"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_gp2" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.gp2.id
  instance_id = module.ec2_public.id[0]
}

/*
resource "aws_volume_attachment" "this_gp2" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.gp2.id
  instance_id = module.ec2_public_i.id[0]
}
*/

################################################################################
# io1 EBS
################################################################################
resource "aws_ebs_volume" "io1" {
  availability_zone = "eu-central-1a"
  size              = 32
  type              = "io1"
  iops              = 1600 //Iops to volume size maximum ratio is 50

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_io1" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.io1.id
  instance_id = module.ec2_public.id[0]
}

################################################################################
# io2 EBS
################################################################################
resource "aws_ebs_volume" "io2" {
  availability_zone = "eu-central-1a"
  size              = 128
  type              = "io2"
  iops              = 6400 //Iops to volume size maximum ratio is 50

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_io2" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.io2.id
  instance_id = module.ec2_public.id[0]
}

################################################################################
# sc1 EBS (read: 20 IOPS / write: 21 IOPS)
################################################################################
resource "aws_ebs_volume" "sc1" {
  availability_zone = "eu-central-1a"
  size              = 500
  type              = "sc1"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_sc1" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.sc1.id
  instance_id = module.ec2_public.id[0]
}

################################################################################
# st1 EBS (read: 64 IOPS / write: 67 IOPS)
################################################################################
resource "aws_ebs_volume" "st1" {
  availability_zone = "eu-central-1a"
  size              = 500
  type              = "st1"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_st1" {
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.st1.id
  instance_id = module.ec2_public.id[0]
}


################################################################################
# Data sources to get VPC, subnets and security group details
################################################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

################################################################################
# EC2
################################################################################
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "this" {
  key_name   = "${local.user_tag.Owner}${local.user_tag.Test}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCVPI+y9VK/2KhV0kNH1boKE3xTkVIo57fWX1qf8+AR4uu+IIr1sM4LLWcbhTR4WY8okfzv9LoCl/LWg30ODsbLuYX2heamZOuSg5CyFSJj6i2RgS2M2wppKLo13+tEqUm4c4E6dnVk2YHeDs7A5asL1IUGnqvcpey2+ZMTgCEa6nfqxitSl3wWSuMZpNUTXtnQh/3Yp1dMlHjdUuiUCHEKIPyHdz2mF/i6yEf4RPLFWVKpX+o1TpfnoVlFipiobcqiZ0SOOgJsbqWGrykrdnYbvOYtKBpNF3OSTZdBaxRHtH907ykre+9gqTPnQFqq3hncUNQuQvpiv9SlZyuCVmr5 andreabortolossi@Andreas-MBP.lan"

  tags = local.user_tag
}

################################################################################
# Attached disk
# t2.micro (read: 1541 IOPS / write: 1540 IOPS)
################################################################################
module "ec2_public" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "public_server"
  instance_count              = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]

  tags = merge(local.user_tag, local.ec2_tag_public)
}

################################################################################
# Attached disk
# i3.large (read: 23.000 IOPS / write: 23.900 IOPS)
################################################################################
module "ec2_public_i" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "public_server_i"
  instance_count              = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "i3.large"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]

  tags = merge(local.user_tag, local.ec2_tag_public)
}


module "aws_security_group_server" {
  source      = "../../modules_AWS/terraform-aws-security-group-master"
  name        = "server_security_group"
  description = "Security group for servers"
  vpc_id      = data.aws_vpc.default.id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8
      to_port     = 0
      protocol    = "icmp"
      description = "ICMP"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "allow all outbound"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(local.user_tag, local.security_group_tag_ec2)
}
