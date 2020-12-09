provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "RDS"
  }
  security_group_tag = {
    scope = "db_server"
  }
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
# DB (with its own security group)
################################################################################
module "db" {
  source = "../../../modules_AWS/terraform-aws-rds-master/"

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
  publicly_accessible     = true
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

  tags = merge(local.user_tag, local.security_group_tag)
}
