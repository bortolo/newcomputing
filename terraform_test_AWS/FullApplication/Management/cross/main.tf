provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner       = var.awsusername
    Test        = "AMI"
    Environment = "cross"
  }
}

################################################################################
# Secret Manager
################################################################################
module "db-secrets" {
  source = "../../../../modules_AWS/terraform-aws-secrets-manager-master"
  secrets = [
    {
      name        = var.db_secret_name
      description = "db user and password"
      secret_key_value = {
        USERNAME     = var.db_username
        PASSWORD     = var.db_password
        DATABASE_URL = var.db_private_dns
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
  source            = "../../../../modules_AWS/terraform-aws-iam-master/modules/iam-assumable-role"
  trusted_role_arns = []
  trusted_role_services = [
    "ec2.amazonaws.com"
  ]
  create_role             = true
  create_instance_profile = true
  role_name               = var.iam_role_name
  role_requires_mfa       = false
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]

  tags = local.user_tag
}

################################################################################
# Key pair name for the EC2 instances
################################################################################
resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCVPI+y9VK/2KhV0kNH1boKE3xTkVIo57fWX1qf8+AR4uu+IIr1sM4LLWcbhTR4WY8okfzv9LoCl/LWg30ODsbLuYX2heamZOuSg5CyFSJj6i2RgS2M2wppKLo13+tEqUm4c4E6dnVk2YHeDs7A5asL1IUGnqvcpey2+ZMTgCEa6nfqxitSl3wWSuMZpNUTXtnQh/3Yp1dMlHjdUuiUCHEKIPyHdz2mF/i6yEf4RPLFWVKpX+o1TpfnoVlFipiobcqiZ0SOOgJsbqWGrykrdnYbvOYtKBpNF3OSTZdBaxRHtH907ykre+9gqTPnQFqq3hncUNQuQvpiv9SlZyuCVmr5 andreabortolossi@Andreas-MBP.lan"

  tags = local.user_tag
}

################################################################################
# Data sources to create custom VPC and custom subnets for MGMT
################################################################################
module "vpc" {
  source = "../../../../modules_AWS/terraform-aws-vpc-master"
  name   = "management"
  cidr   = "10.0.0.0/24"
  azs    = ["eu-central-1a"]
  public_subnets = ["10.0.0.0/26"]
  public_subnet_tags = {
    subnet_type = "public"
  }
  enable_dhcp_options      = true
  dhcp_options_domain_name = "eu-central-1.compute.internal"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.vpc_tags
}

################################################################################
# Select which AMI to use
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

################################################################################
# EC2
################################################################################
module "ec2_MGMT" {
  source                      = "../../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "mgmt"
  instance_count              = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = yes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group.this_security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]

  tags = var.ec2_tags
}

module "aws_security_group" {
  source      = "../../../../modules_AWS/terraform-aws-security-group-master"
  name        = "mgmt_security_group"
  description = "Security group for mgmt servers"
  vpc_id      = module.vpc.vpc_id
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

  tags = var.ec2_tags
}
