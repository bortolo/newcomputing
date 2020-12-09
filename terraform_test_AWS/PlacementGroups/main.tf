provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "PlacementGroups"
  }

  ec2_tag_cluster   = { server_type = "cluster" }
  ec2_tag_spread    = { server_type = "spread" }
  ec2_tag_partition = { server_type = "partition" }
  security_group_tag_ec2 = {
    scope = "security_server"
  }
}


resource "aws_placement_group" "cluster" {
  name     = "cluster"
  strategy = "cluster"
}

resource "aws_placement_group" "partition" {
  name     = "partition"
  strategy = "partition"
}

resource "aws_placement_group" "spread" {
  name     = "spread"
  strategy = "spread"
}

module "vpc" {
  source = "../../modules_AWS/terraform-aws-vpc-master"

  name = "complete-example"

  cidr = "10.0.0.0/16"

  azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  public_subnets = ["10.0.48.0/21", "10.0.64.0/21", "10.0.80.0/21"]
  public_subnet_tags = {
    subnet_type = "public"
  }

  create_database_subnet_group   = false
  enable_dns_hostnames           = true
  enable_dns_support             = true
  enable_classiclink             = false
  enable_classiclink_dns_support = false
  enable_nat_gateway             = false
  single_nat_gateway             = false
  one_nat_gateway_per_az         = false
  enable_vpn_gateway             = false
  enable_dhcp_options            = true

  tags = local.user_tag
}

################################################################################
# EC2
################################################################################
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "image-id"
    values = ["ami-0e1ce3e0deb8896d2"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "this" {
  key_name   = "${local.user_tag.Owner}${local.user_tag.Test}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCVPI+y9VK/2KhV0kNH1boKE3xTkVIo57fWX1qf8+AR4uu+IIr1sM4LLWcbhTR4WY8okfzv9LoCl/LWg30ODsbLuYX2heamZOuSg5CyFSJj6i2RgS2M2wppKLo13+tEqUm4c4E6dnVk2YHeDs7A5asL1IUGnqvcpey2+ZMTgCEa6nfqxitSl3wWSuMZpNUTXtnQh/3Yp1dMlHjdUuiUCHEKIPyHdz2mF/i6yEf4RPLFWVKpX+o1TpfnoVlFipiobcqiZ0SOOgJsbqWGrykrdnYbvOYtKBpNF3OSTZdBaxRHtH907ykre+9gqTPnQFqq3hncUNQuQvpiv9SlZyuCVmr5 andreabortolossi@Andreas-MBP.lan"

  tags = local.user_tag
}

module "ec2_cluster" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "cluster_server"
  instance_count              = 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "c5a.large"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_id                   = tolist(module.vpc.public_subnets)[0]

  placement_group = aws_placement_group.cluster.id

  tags = merge(local.user_tag, local.ec2_tag_cluster)
}

module "ec2_spread" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "spread_server"
  instance_count              = 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "c5a.large"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_ids                  = module.vpc.public_subnets

  placement_group = aws_placement_group.spread.id

  tags = merge(local.user_tag, local.ec2_tag_spread)
}

module "ec2_partition" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "partition_server"
  instance_count              = 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "c5a.large"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_ids                  = module.vpc.public_subnets

  placement_group = aws_placement_group.partition.id

  tags = merge(local.user_tag, local.ec2_tag_partition)
}

module "aws_security_group_server" {
  source      = "../../modules_AWS/terraform-aws-security-group-master"
  name        = "server_security_group"
  description = "Security group for servers"
  vpc_id      = module.vpc.vpc_id
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
    {
      from_port   = 5201
      to_port     = 5201
      protocol    = "tcp"
      description = "iperf3"
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
