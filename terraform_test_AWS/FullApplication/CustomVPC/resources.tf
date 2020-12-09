################################################################################
# Route53
################################################################################
resource "aws_route53_zone" "private" {
  name = "private_host_zone"
  vpc {
    vpc_id = module.vpc.vpc_id
    //vpc_id = data.aws_vpc.default.id
  }

  tags = local.user_tag
}

resource "aws_route53_record" "database_1" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "${var.db_private_dns}_1"
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.db_1.this_db_instance_address}"]
}

resource "aws_route53_record" "database_2" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "${var.db_private_dns}_2"
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.db_2.this_db_instance_address}"]
}

resource "aws_route53_record" "database_3" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "${var.db_private_dns}_3"
  type    = "CNAME"
  ttl     = "300"
  records = ["${module.db_3.this_db_instance_address}"]
}

################################################################################
# EC2
# ec_1 is in custom VPC in public subnet
# ec_2 is in custom VPC in database subnet
# ec_3 is in default VPC in public subnet
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

resource "aws_key_pair" "this_2" {
  key_name   = "${local.user_tag.Owner}${local.user_tag.Test}_2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvI/Wyxu/1unb/Ex66/yG6Y2jgghqX4pIxrcxzZdC0PJo++6AVwWdNakGKb7aMsljvJbJbma3fA2SO5xH73xQXLF4TL5WTUrrY/ZhX+zHef6E0xyZia+R1OUbcjRcldEgmB31ncZpN0RX7yoQ6SKoK0UkHdWV5mcwQ7Atwlum8wFeAFUsgwNX4WwPxx+xi1G4JemD5NUqRN+ZF3+WYaizH+3XumxIjJXr6uGy9AwE7tn6H1WU+NSK0bBS9Z1MZYQvm7VJh1N2DnMNEevY0TmAbDcvqnuHzbK/MaWdGZnv4f8yktjD3qYHE9PMoktln749CP0PIHQJ8vg2z5BV9xbxTyiKPLWF9ahffVN4nxtVABhWqMNAtjyESdFscXbTv0FUV5iEBP7yw6nMfq/3zo3ZO9tnP9DOKLMI8f4PfuzL1MUOizwrpe+n5+CWZLjD5vLFsqw+KORBVfleCZoz14otGgLTos74O+XlyY07+Ub9RW7ao3JsQGhNLfUHS2ofyBX0= ubuntu@ip-10-0-143-185"

  tags = local.user_tag
}

module "ec2_1" {
  source                      = "../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "server_1"
  instance_count              = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_custom.this_security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = module.iam_assumable_role_custom.this_iam_instance_profile_name

  tags = merge(local.user_tag, local.ec2_tag)
}

module "ec2_2" {
  source                      = "../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "server_2"
  instance_count              = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this_2.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_custom.this_security_group_id]
  subnet_id                   = module.vpc.database_subnets[0]
  iam_instance_profile        = module.iam_assumable_role_custom.this_iam_instance_profile_name

  tags = merge(local.user_tag, local.ec2_tag)
}

module "ec2_3" {
  source                      = "../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "server_3"
  instance_count              = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_default.this_security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]
  iam_instance_profile        = module.iam_assumable_role_custom.this_iam_instance_profile_name

  tags = merge(local.user_tag, local.ec2_tag)
}

module "aws_security_group_custom" {
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

module "aws_security_group_default" {
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
# db_2 is in custom VPC in public subnet
# db_3 is in default VPC in public subnet
################################################################################

module "db_1" {
  source                  = "../../../modules_AWS/terraform-aws-rds-master/"
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
  vpc_security_group_ids  = [module.aws_security_group_db_custom.this_security_group_id]
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


module "db_2" {
  source                  = "../../../modules_AWS/terraform-aws-rds-master/"
  identifier              = "demodb2"
  engine                  = "mysql"
  engine_version          = "8.0.20"
  instance_class          = "db.t2.micro"
  allocated_storage       = 5
  storage_encrypted       = false
  name                    = "demodb2"
  username                = var.db_username
  password                = var.db_password
  port                    = "3306"
  vpc_security_group_ids  = [module.aws_security_group_db_custom.this_security_group_id]
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  publicly_accessible     = false
  backup_retention_period = 0
  availability_zone       = "eu-central-1a"
  subnet_ids              = module.vpc.public_subnets
  family                  = "mysql8.0"
  major_engine_version    = "8.0"

  tags = local.user_tag
}

module "db_3" {
  source                  = "../../../modules_AWS/terraform-aws-rds-master/"
  identifier              = "demodb3"
  engine                  = "mysql"
  engine_version          = "8.0.20"
  instance_class          = "db.t2.micro"
  allocated_storage       = 5
  storage_encrypted       = false
  name                    = "demodb3"
  username                = var.db_username
  password                = var.db_password
  port                    = "3306"
  vpc_security_group_ids  = [module.aws_security_group_db_default.this_security_group_id]
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  publicly_accessible     = false
  backup_retention_period = 0
  availability_zone       = "eu-central-1a"
  subnet_ids              = data.aws_subnet_ids.all.ids
  family                  = "mysql8.0"
  major_engine_version    = "8.0"

  tags = local.user_tag
}

module "aws_security_group_db_custom" {
  source      = "../../../modules_AWS/terraform-aws-security-group-master"
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


module "aws_security_group_db_default" {
  source      = "../../../modules_AWS/terraform-aws-security-group-master"
  name        = "db_security_group_default"
  description = "Security group for db mysql in default VPC"
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
