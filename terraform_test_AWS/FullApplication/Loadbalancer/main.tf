provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "Loadbalancer"
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

  database_route_table_tags = {
    type = "RDS db"
  }
}

################################################################################
# Data sources to create custom VPC and custom subnets (public and database)
################################################################################
module "vpc" {
  source = "../../../modules_AWS/terraform-aws-vpc-master"
  name   = "customVPC"
  cidr   = "10.0.0.0/16"
  azs    = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  public_subnets = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]
  public_subnet_tags = {
    subnet_type = "public"
  }

  database_subnets = ["10.0.176.0/21", "10.0.184.0/21", "10.0.192.0/21"]
  database_subnet_tags = {
    subnet_type = "database"
  }

  enable_dhcp_options      = true
  dhcp_options_domain_name = "eu-central-1.compute.internal"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.user_tag
}

################################################################################
# Secret Manager
################################################################################
module "db-secrets" {
  source = "../../../modules_AWS/terraform-aws-secrets-manager-master"
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

data "aws_secretsmanager_secret_version" "db-secret" {
  secret_id = module.db-secrets.secret_ids[0]
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

resource "aws_route53_record" "database" {
  zone_id = aws_route53_zone.private.zone_id
  name    = var.db_private_dns
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.db.this_db_instance_address}"]
}

################################################################################
# IAM assumable role with custom policies
################################################################################
module "iam_assumable_role_custom" {
  source            = "../../../modules_AWS/terraform-aws-iam-master/modules/iam-assumable-role"
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

##################################################################
# Network Load Balancer with Elastic IPs attached
##################################################################

module "nlb" {
  source = "../../../modules_AWS/terraform-aws-alb-master"

  name = "complete-nlb"

  load_balancer_type = "network"

  vpc_id = module.vpc.vpc_id

  //  Use `subnet_mapping` to attach EIPs
  subnet_mapping = [{ allocation_id : aws_eip.lb[0].id, subnet_id : module.vpc.public_subnets[0] }]

  // TCP_UDP, UDP, TCP
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name_prefix      = "tu1-"
      backend_protocol = "TCP"
      backend_port     = 8080
      target_type      = "instance"

      tags = {
        tcp_udp = true
      }
    },
  ]

  tags = local.user_tag
}

resource "aws_lb_target_group_attachment" "test" {
  count            = length(module.ec2_FE.id)
  target_group_arn = module.nlb.target_group_arns[0]
  target_id        = module.ec2_FE.id[count.index]
}

resource "aws_eip" "lb" {
  count = 1
  vpc   = true

  tags = local.user_tag
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
  source                      = "../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "fe_server"
  instance_count              = 3
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_FE.this_security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = module.iam_assumable_role_custom.this_iam_instance_profile_name

  tags = merge(local.user_tag, local.ec2_tag)
}

module "aws_security_group_FE" {
  source      = "../../../modules_AWS/terraform-aws-security-group-master"
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
  subnet_ids              = module.vpc.database_subnets
  family                  = "mysql8.0"
  major_engine_version    = "8.0"

  tags = local.user_tag
}

module "aws_security_group_db" {
  source      = "../../../modules_AWS/terraform-aws-security-group-master"
  name        = "db_security_group"
  description = "Security group for db mysql"
  vpc_id      = module.vpc.vpc_id
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
