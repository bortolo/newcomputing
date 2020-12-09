################################################################################
# Get information about cross services
################################################################################
data "aws_secretsmanager_secret" "db-secret" {
  name = var.db_secret_name
}

data "aws_secretsmanager_secret_version" "db-secret-version" {
  secret_id = data.aws_secretsmanager_secret.db-secret.id
}

################################################################################
# Data sources to create custom VPC and custom subnets (public and database)
################################################################################
module "vpc" {
  source = "../../../../modules_AWS/terraform-aws-vpc-master"
  name   = var.vpc_name
  cidr   = var.vpc_cidr
  azs    = var.vpc_azs
  public_subnets = var.vpc_public_subnets
  public_subnet_tags = {
    subnet_type = "public"
  }
  database_subnets = var.vpc_database_subnets
  database_subnet_tags = {
    subnet_type = "database"
  }
  enable_dhcp_options      = true
  dhcp_options_domain_name = "eu-central-1.compute.internal"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.vpc_tags
}

################################################################################
# Route53
################################################################################
resource "aws_route53_zone" "private" {
  name = "private_host_zone"
  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = var.route53_tags
}

resource "aws_route53_record" "database" {
  zone_id = aws_route53_zone.private.zone_id
  name    = jsondecode(data.aws_secretsmanager_secret_version.db-secret-version.secret_string)["DATABASE_URL"]
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.db.this_db_instance_address}"]
}

##################################################################
# Network Load Balancer with Elastic IPs attached
##################################################################

module "nlb" {
  source = "../../../../modules_AWS/terraform-aws-alb-master"
  name = var.nlb_name
  load_balancer_type = "network"
  vpc_id = module.vpc.vpc_id
  subnet_mapping = [{ allocation_id : aws_eip.lb[0].id, subnet_id : module.vpc.public_subnets[0] }]
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

  tags = var.nlb_tags
}

resource "aws_lb_target_group_attachment" "test" {
  count            = length(module.ec2_FE.id)
  target_group_arn = module.nlb.target_group_arns[0]
  target_id        = module.ec2_FE.id[count.index]
}

resource "aws_eip" "lb" {
  count = 1
  vpc   = true

  tags = var.nlb_tags
}

################################################################################
# EC2
################################################################################
module "ec2_FE" {
  source                      = "../../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = var.ec2_name
  instance_count              = var.ec2_number_of_instances
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_pair_name
  associate_public_ip_address = var.ec2_public_ip
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_FE.this_security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = var.ec2_iam_role_name //it is highly dependent on terraform custom module
  user_data                   = var.ec2_user_data

  tags = var.ec2_tags
}

module "aws_security_group_FE" {
  source      = "../../../../modules_AWS/terraform-aws-security-group-master"
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

  tags = var.ec2_tags
}

################################################################################
# DB
################################################################################
module "db" {
  source                  = "../../../../modules_AWS/terraform-aws-rds-master/"
  identifier              = var.db_identifier
  engine                  = "mysql"
  engine_version          = "8.0.20"
  instance_class          = var.db_instance_class
  allocated_storage       = 5
  storage_encrypted       = false
  name                    = var.db_name
  username                = jsondecode(data.aws_secretsmanager_secret_version.db-secret-version.secret_string)["USERNAME"]
  password                = jsondecode(data.aws_secretsmanager_secret_version.db-secret-version.secret_string)["PASSWORD"]
  port                    = "3306"
  vpc_security_group_ids  = [module.aws_security_group_db.this_security_group_id]
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  publicly_accessible     = false
  backup_retention_period = 0
  subnet_ids              = module.vpc.database_subnets
  family                  = "mysql8.0"
  major_engine_version    = "8.0"

  tags = var.db_tags
}

module "aws_security_group_db" {
  source      = "../../../../modules_AWS/terraform-aws-security-group-master"
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

  tags = var.db_tags
}
