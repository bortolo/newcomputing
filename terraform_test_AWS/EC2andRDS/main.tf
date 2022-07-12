provider "aws" {
  region = var.region
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "RDS endpoint"
  }
  security_group_tag_db     = { scope = "db_server" }
  ec2_tag                   = { server_type = "fe_server" }
  security_group_tag_ec2    = { scope = "fe_server" }
  database_route_table_tags = { type = "RDS db" }
}

################################################################################
# Data sources to create custom VPC and custom subnets (public and database)
################################################################################
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
  name   = "EC2andRDS"
  cidr   = "10.0.0.0/16"
  azs    = ["eu-central-1a","eu-central-1b"]

  public_subnets = ["10.0.128.0/20"]
  public_subnet_tags = {
    subnet_type = "public"
  }

  database_subnets = ["10.0.176.0/21", "10.0.184.0/21"]
  database_subnet_tags = {
    subnet_type = "database"
  }

  enable_dhcp_options      = true
  dhcp_options_domain_name = "eu-central-1.compute.internal"

  create_database_subnet_group = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.user_tag
}

################################################################################
# Secret Manager
################################################################################
module "db-secrets" {
  source = "../../modules_AWS/terraform-aws-secrets-manager-master"
  secrets = [
    {
      name        = var.db_secret_name
      description = "db user and password"
      secret_key_value = {
        username = var.db_username
        password = var.db_password
        db_dns   = var.db_private_dns
      }
      recovery_window_in_days = 7
    },
  ]

  tags = local.user_tag
}

################################################################################
# IAM assumable role with custom policies
################################################################################
module "iam_assumable_role_custom" {
  source            = "github.com/terraform-aws-modules/terraform-aws-iam/modules/iam-assumable-role"
  trusted_role_arns = []
  trusted_role_services = [
    "ec2.amazonaws.com"
  ]
  create_role             = true
  create_instance_profile = true
  role_name               = "custom"
  role_requires_mfa       = false
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]

  tags = local.user_tag
}



################################################################################
# Route53
################################################################################
resource "aws_route53_zone" "private" {
  name = "private_host_zone"
  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = local.user_tag
}



################################################################################
# EC2
# ec_1 is in custom VPC in public subnet
################################################################################

resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = var.public_key

  tags = local.user_tag
}

module "ec2_1" {
  source                      = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"
  name                        = var.ec2_name
  instance_count              = var.ec2_number_of_instances
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = var.ec2_public_ip
  monitoring                  = var.ec2_detailed_monitoring
  vpc_security_group_ids      = [module.aws_security_group_custom.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = module.iam_assumable_role_custom.iam_instance_profile_name

  tags = merge(local.user_tag, local.ec2_tag)
}

module "aws_security_group_custom" {
  source      = "github.com/terraform-aws-modules/terraform-aws-security-group"
  name        = "FE_security_group"
  description = "Security group for front-end servers"
  vpc_id      = module.vpc.vpc_id
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

################################################################################
# DBs
# db_1 is in custom VPC in database subnet
################################################################################

resource "aws_route53_record" "database_1" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "${var.db_private_dns}_1"
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.db_1.db_instance_address}"]
}

module "db_1" {
  source                  = "github.com/terraform-aws-modules/terraform-aws-rds"
  identifier              = "demodb1"
  engine                  = "mysql"
  engine_version          = "8.0.20"
  instance_class          = "db.t2.micro"
  allocated_storage       = 5
  storage_encrypted       = false
  name                    = "demodb1"
  username                = var.db_username
  password                = var.db_password
  port                    = "3306"
  vpc_security_group_ids  = [module.aws_security_group_db_custom.security_group_id]
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  publicly_accessible     = false
  backup_retention_period = 0
  availability_zone       = "eu-central-1a"
  db_subnet_group_name    = module.vpc.database_subnet_group
  family                  = "mysql8.0"
  major_engine_version    = "8.0"

  tags = local.user_tag
}

module "aws_security_group_db_custom" {
  source      = "github.com/terraform-aws-modules/terraform-aws-security-group"
  name        = "db_security_group_custom"
  description = "Security group for db mysql in custom VPC"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "allow all inbound"
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
