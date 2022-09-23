
provider "aws" {
  region = var.region
}

locals {

  user_tag = {
    Owner = var.awsusername
    Test  = "TransitGateway-01"
  }
}

################################################################################
# VPC-A
################################################################################

resource "aws_vpc" "vpc-a" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-A"
  }

}

resource "aws_internet_gateway" "gw-a" {
  vpc_id = aws_vpc.vpc-a.id
  tags = {
    Name = "a-igw"
  }
}

# Public subent of VPC-A

resource "aws_subnet" "a-public" {
  vpc_id     = aws_vpc.vpc-a.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "a-public-subnet"
  }
}

resource "aws_route_table" "a-public" {
  vpc_id = aws_vpc.vpc-a.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-a.id
  }
    tags = {
    Name = "a-public-rt"
  }
}

resource "aws_route_table_association" "a-public" {
  subnet_id      = aws_subnet.a-public.id
  route_table_id = aws_route_table.a-public.id
}

# Private subent of VPC-A

resource "aws_subnet" "a-private" {
  vpc_id     = aws_vpc.vpc-a.id
  cidr_block = "10.0.1.0/24"
    tags = {
    Name = "a-private-subnet"
  }
}

resource "aws_route_table" "a-private" {
  vpc_id = aws_vpc.vpc-a.id
    tags = {
    Name = "a-private-rt"
  }
}

resource "aws_route_table_association" "a-private" {
  subnet_id      = aws_subnet.a-private.id
  route_table_id = aws_route_table.a-private.id
}

################################################################################
# VPC-B
################################################################################

resource "aws_vpc" "vpc-b" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
    tags = {
    Name = "VPC-B"
  }
}

resource "aws_subnet" "b-private" {
  vpc_id     = aws_vpc.vpc-b.id
  cidr_block = "10.1.0.0/24"
    tags = {
    Name = "b-private-subnet"
  }
}

resource "aws_route_table" "b-private" {
  vpc_id = aws_vpc.vpc-b.id
    tags = {
    Name = "b-private-rt"
  }
}

resource "aws_route_table_association" "b-private" {
  subnet_id      = aws_subnet.b-private.id
  route_table_id = aws_route_table.b-private.id
}

################################################################################
# VPC-C
################################################################################

resource "aws_vpc" "vpc-c" {
  cidr_block       = "10.2.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-C"
  }
}

resource "aws_subnet" "c-private" {
  vpc_id     = aws_vpc.vpc-c.id
  cidr_block = "10.2.0.0/24"
    tags = {
    Name = "c-private-subnet"
  }
}

resource "aws_route_table" "c-private" {
  vpc_id = aws_vpc.vpc-c.id
  tags = {
    Name = "c-private-rt"
  }
}

resource "aws_route_table_association" "c-private" {
  subnet_id      = aws_subnet.c-private.id
  route_table_id = aws_route_table.c-private.id
}

################################################################################
# EC2
################################################################################

resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = var.public_key
  tags = {
    Name = "tgway-key"
  }
}

# Jumphost

resource "aws_instance" "jumphost" {
  ami                         = "ami-0bd39c806c2335b95"
  instance_type               = "t3.micro"
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.a-public.id
  security_groups             = [aws_security_group.jumphost.id]
  tags = {
    Name = "Jumphost"
  }
}

resource "aws_security_group" "jumphost" {
  vpc_id      = aws_vpc.vpc-a.id
  tags = {
    Name = "jumphost"
  }
}

resource "aws_security_group_rule" "ssh-jumphost" {
  type              = "ingress"
  from_port        = 22
  to_port          = 22
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = aws_security_group.jumphost.id
}

resource "aws_security_group_rule" "all-jumphost" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.jumphost.id
}

# VM private A

resource "aws_instance" "vm-a" {
  ami                         = "ami-0bd39c806c2335b95"
  instance_type               = "t3.micro"
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.a-private.id
  security_groups             = [aws_security_group.vm-a.id]
  tags = {
    Name = "vm-a"
  }
}

resource "aws_security_group" "vm-a" {
  vpc_id      = aws_vpc.vpc-a.id
  tags = {
    Name = "vm-a"
  }
}

resource "aws_security_group_rule" "ssh-vm-a" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.vm-a.id
}

resource "aws_security_group_rule" "icmp-vm-a" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vm-a.id
}



# VM private B

# VM private C


/*
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = var.public_key
  tags = local.user_tag
}

module "ec2" {
  //source                      = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = var.ec2_name

  instance_count              = 1
  
  ami                         = "ami-0bd39c806c2335b95" //AWS Linux AMI
  instance_type               = "t2.micro"
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group.security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]
  user_data                   = data.cloudinit_config.example.rendered
  iam_instance_profile        = module.iam_assumable_role_custom.iam_instance_profile_name

  tags = local.user_tag
}

module "aws_security_group" {
  source      = "github.com/terraform-aws-modules/terraform-aws-security-group"
  name        = "security_group"
  description = "Security group for Kinesis"
  vpc_id      = data.aws_vpc.default.id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH port"
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

module "iam_assumable_role_custom" {
  source            = "github.com/terraform-aws-modules/terraform-aws-iam/modules/iam-assumable-role"
  trusted_role_arns = []
  trusted_role_services = [
    "ec2.amazonaws.com"
  ]
  create_role             = true
  create_instance_profile = true
  role_name               = "ec2-admin-firehose"
  role_requires_mfa       = false
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
  ]

  tags = local.user_tag
}
*/