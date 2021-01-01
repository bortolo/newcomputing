provider "aws" {
  region = var.region
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
  count = var.standard_create ? 1 : 0
  availability_zone = "eu-central-1a"
  size              = var.standard_size
  type              = "standard"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_standard" {
  count = var.standard_create ? 1 : 0
  device_name = var.standard_device_name
  volume_id   = aws_ebs_volume.standard[0].id
  instance_id = module.ec2_public_t.id[0]
}

################################################################################
# gp2 EBS
# t2.micro (read: 1543 IOPS / write: 1542 IOPS)
# i3.large (read: 1542 IOPS / write: 1542 IOPS)
################################################################################
resource "aws_ebs_volume" "gp2" {
  count = var.gp2_create ? 1 : 0
  availability_zone = "eu-central-1a"
  size              = var.gp2_size
  type              = "gp2"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_gp2" {
  count = var.gp2_create ? 1 : 0
  device_name = var.gp2_device_name
  volume_id   = aws_ebs_volume.gp2[0].id
  instance_id = module.ec2_public_t.id[0]
}

################################################################################
# io1 EBS
################################################################################
resource "aws_ebs_volume" "io1" {
  count = var.io1_create ? 1 : 0
  availability_zone = "eu-central-1a"
  size              = var.io1_size
  type              = "io1"
  iops              = var.io1_iops //Iops to volume size maximum ratio is 50

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_io1" {
  count = var.io1_create ? 1 : 0
  device_name = var.io1_device_name
  volume_id   = aws_ebs_volume.io1[0].id
  instance_id = module.ec2_public_t.id[0]
}

################################################################################
# io2 EBS
################################################################################
resource "aws_ebs_volume" "io2" {
  count = var.io2_create ? 1 : 0
  availability_zone = "eu-central-1a"
  size              = var.io2_size
  type              = "io2"
  iops              = var.io2_iops //Iops to volume size maximum ratio is 50

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_io2" {
  count = var.io2_create ? 1 : 0
  device_name = var.io2_device_name
  volume_id   = aws_ebs_volume.io2[0].id
  instance_id = module.ec2_public_t.id[0]
}

################################################################################
# sc1 EBS (read: 20 IOPS / write: 21 IOPS)
################################################################################
resource "aws_ebs_volume" "sc1" {
  count = var.sc1_create ? 1 : 0
  availability_zone = "eu-central-1a"
  size              = var.sc1_size
  type              = "sc1"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_sc1" {
  count = var.sc1_create ? 1 : 0
  device_name = var.sc1_device_name
  volume_id   = aws_ebs_volume.sc1[0].id
  instance_id = module.ec2_public_t.id[0]
}

################################################################################
# st1 EBS (read: 64 IOPS / write: 67 IOPS)
################################################################################
resource "aws_ebs_volume" "st1" {
  count = var.st1_create ? 1 : 0
  availability_zone = "eu-central-1a"
  size              = var.st1_size
  type              = "st1"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_st1" {
  count = var.st1_create ? 1 : 0
  device_name = var.st1_device_name
  volume_id   = aws_ebs_volume.st1[0].id
  instance_id = module.ec2_public_t.id[0]
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
resource "aws_key_pair" "this" {
  key_name   = "ebs-key"
  public_key = var.public_key

  tags = local.user_tag
}

################################################################################
# Attached disk
# t2.micro (read: 1541 IOPS / write: 1540 IOPS)
################################################################################
module "ec2_public_t" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "public_server_t"
  instance_count              = var.ec2_t_instance ? 1 : 0
  ami                         = var.ec2_ami_id
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
  instance_count              = var.ec2_i_instance ? 1 : 0
  ami                         = var.ec2_ami_id
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
