provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "EC2andRDS"
  }
  security_group_tag_db = {
    scope = "db_server"
  }
  ec2_tag = {
    server_type = "fe_server"
  }
  security_group_tag_ec2 = {
    scope = "fe_server"
  }
}

################################################################################
# Data sources to get VPC, subnets
################################################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

################################################################################
# Route53
################################################################################
resource "aws_route53_zone" "private" {
  name = "private_host_zone"
  vpc {
    vpc_id = data.aws_vpc.default.id
  }

  tags = local.user_tag
}

resource "aws_route53_record" "database" {
  zone_id = aws_route53_zone.private.zone_id
  name    = var.db_private_dns
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.db.this_db_instance_address}"]
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

module "ec2_FE" {
  source                 = "../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                   = "fe_server"
  instance_count         = 1
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.this.key_name
  monitoring             = false
  vpc_security_group_ids = [module.aws_security_group_FE.this_security_group_id]
  subnet_id              = tolist(data.aws_subnet_ids.all.ids)[0]

  tags = merge(local.user_tag, local.ec2_tag)
}

module "aws_security_group_FE" {
  source      = "../../../modules_AWS/terraform-aws-security-group-master"
  name        = "FE_security_group"
  description = "Security group for front-end servers"
  vpc_id      = data.aws_vpc.default.id
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "http port"
      cidr_blocks = "0.0.0.0/0"
    },
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

  tags = merge(local.user_tag, local.security_group_tag_ec2)
}

################################################################################
# DB
################################################################################
module "db" {
  source                  = "../../../modules_AWS/terraform-aws-rds-master/"
  identifier              = "demodb"
  engine                  = "mysql"
  engine_version          = "8.0.20"
  instance_class          = "db.t2.micro"
  allocated_storage       = 5
  storage_encrypted       = false
  name                    = "demodb"
  username                = var.db_username
  password                = var.db_password
  port                    = "3306"
  vpc_security_group_ids  = [module.aws_security_group_db.this_security_group_id]
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  publicly_accessible     = false
  backup_retention_period = 0
  subnet_ids              = data.aws_subnet_ids.all.ids
  family                  = "mysql8.0"
  major_engine_version    = "8.0"

  tags = local.user_tag
}

module "aws_security_group_db" {
  source      = "../../../modules_AWS/terraform-aws-security-group-master"
  name        = "db_security_group"
  description = "Security group for db mysql"
  vpc_id      = data.aws_vpc.default.id
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "allo all inbound"
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

  tags = merge(local.user_tag, local.security_group_tag_db)
}
