provider "aws" {
  region = var.region
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "VPC-tutorial-NAT-instance"
  }
}

################################################################################
# VPC (Virtual Private Cloud)
################################################################################
# Soft limit of 5 VPC per region
# max CIDR per VPC is 5
# for each CIDR
# 1) min size /28
# 2) max size /16
# Only the private IP are allowed (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
# Your VPC CIDR should not overlap with your others networks (if you are going to connect them)
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default" #Using either of the other options (dedicated or host) costs at least $2/hr.

  tags = local.user_tag
}

################################################################################
# Subnets
################################################################################
# AWS reserves 5 IPs addresses (first 4 and last 1 IP address) in each subnet:
# Network address | VPC router | mapping to the AWS DNS | future use | network broadcast (not supported in AWS so it is reserved)

resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "${var.region}a"
  cidr_block = "10.0.0.0/24"

  tags = local.user_tag
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "${var.region}b"
  cidr_block = "10.0.1.0/24"

  tags = local.user_tag
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "${var.region}a"
  cidr_block = "10.0.16.0/20"

  tags = local.user_tag
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "${var.region}b"
  cidr_block = "10.0.32.0/20"

  tags = local.user_tag
}

################################################################################
# IGW (Internet gateway)
################################################################################
# One VPC can be attacched to one signle IGW
# IGW is also a NAT for the instances that have a public IPv4

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = local.user_tag
}

################################################################################
# Route Table
################################################################################

# Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = local.user_tag
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "r" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.gw.id
}

# Private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = local.user_tag
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "nat_instance" {
  count                     = var.nat_instance_or_gateway?1:0
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  instance_id               = module.ec2_NAT_instance.id[0]
}

resource "aws_route" "nat_gateway" {
  count                     = var.nat_instance_or_gateway?0:1
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.gw[0].id
}

################################################################################
# EC2
################################################################################
resource "aws_key_pair" "this" {
  key_name   = "vpc-key"
  public_key = var.public_key

  tags = local.user_tag
}

module "ec2_public" {
  source                      = "../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "public_server_a"
  instance_count              = 1
  ami                         = var.ec2_ami_id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_id                   = aws_subnet.public_subnet_a.id

  tags = local.user_tag
}

module "ec2_private" {
  source                      = "../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "private_server_a"
  instance_count              = 1
  ami                         = var.ec2_ami_id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = false
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_id                   = aws_subnet.private_subnet_a.id

  tags = local.user_tag
}

module "aws_security_group_server" {
  source      = "../../../modules_AWS/terraform-aws-security-group-master"
  name        = "server_security_group"
  description = "Security group for servers"
  vpc_id      = aws_vpc.main.id
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

  tags = local.user_tag
}

################################################################################
# NAT instances
################################################################################
# Allows instances in the private subnets to connect to the internet
# Must be launched in a public subnet
# Must disable EC2 flag source/destination check
# Must have Elastic IP attached to it
# Route tabel must be configured to route traffic from private subnets to NAT instance

resource "aws_eip" "nat_ip" {
  count                     = var.nat_instance_or_gateway?1:0
  vpc      = true
}

resource "aws_eip_association" "eip_assoc" {
  count                     = var.nat_instance_or_gateway?1:0
  instance_id   = module.ec2_NAT_instance.id[0]
  allocation_id = aws_eip.nat_ip[0].id
}

module "ec2_NAT_instance" {
  source                      = "../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "NAT_server_a"
  instance_count              = var.nat_instance_or_gateway?1:0
  ami                         = var.ec2_NAT_ami_id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  source_dest_check           = false
  associate_public_ip_address = true
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server_NAT.this_security_group_id]
  subnet_id                   = aws_subnet.public_subnet_a.id

  tags = local.user_tag
}

module "aws_security_group_server_NAT" {
  source      = "../../../modules_AWS/terraform-aws-security-group-master"
  name        = "NAT security group"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.main.id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http allowed from VPC"
      cidr_blocks = aws_vpc.main.cidr_block
    },
        {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https allowed from VPC"
      cidr_blocks = aws_vpc.main.cidr_block
    },
        {
      from_port   = 8
      to_port     = 0
      protocol    = "icmp"
      description = "ICMP"
      cidr_blocks = aws_vpc.main.cidr_block
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

  tags = local.user_tag
}

################################################################################
# NAT gateway
################################################################################
# AWS managed NAT, higher bandwidth, better availability, no admin
# Pay by the hour for usage (es. Frankfurt 0.052$/h) and bandwidth (es. Frankfurt 0.052$/GB)
# NAT is created in a specific AZ, uses an EIP
# cannot be used in a instance in that subnet
# Requires IGW 
# 5 Gbps of bandwidth with automatic scaling up to 45 Gbps
# No security group to manage
# It is resilient in a single AZ (if you want cross AZ fault-tolerance you have to deploy a second NAT gateway)

resource "aws_eip" "nat_gw_ip" {
  count                     = var.nat_instance_or_gateway?0:1
  vpc      = true
}

resource "aws_nat_gateway" "gw" {
  count                     = var.nat_instance_or_gateway?0:1
  allocation_id = aws_eip.nat_gw_ip[0].id
  subnet_id     = aws_subnet.public_subnet_a.id

  # depends_on: terraform meta argument
  # Explicitly specifying a dependency is only necessary when a resource or module 
  # relies on some other resource's behavior but doesn't access any of that resource's 
  # data in its arguments
  # Note: deploy a nat gateway without an internet gateway is usuless
  depends_on = [aws_internet_gateway.gw]

  tags = local.user_tag
}