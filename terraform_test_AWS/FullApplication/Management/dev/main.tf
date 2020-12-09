provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner       = var.awsusername
    Test        = "AMI"
    Environment = "dev"
  }
  ec2_tag = {
    server_type = "fe_server"
  }
  db_tag = {
    type = "test_db"
  }
}

################################################################################
# Create AMI image of the app
################################################################################
resource "aws_ami_from_instance" "example" {
  count              = var.create_AMI ? 1 : 0
  name               = var.AMI_name
  source_instance_id = module.myapp.ec2_id
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
# Create the app infrastructure
################################################################################
module "myapp" {
  source = "../module"

  db_secret_name = var.db_secret_name

  vpc_name             = "custom-dev"
  vpc_cidr             = "10.0.0.0/16"
  vpc_azs              = ["eu-central-1a", "eu-central-1b"]
  vpc_public_subnets   = ["10.0.8.0/21"]
  vpc_database_subnets = ["10.0.16.0/21", "10.0.24.0/21"]
  vpc_tags             = local.user_tag

  route53_tags = local.user_tag

  nlb_name = "nlb-dev"
  nlb_tags = local.user_tag

  ec2_name                = "fe_server-dev"
  ec2_number_of_instances = 2
  ec2_ami_id              = data.aws_ami.ubuntu.id
  ec2_instance_type       = "t2.micro"
  ec2_key_pair_name       = var.key_pair_name
  ec2_public_ip           = true
  ec2_iam_role_name       = var.iam_role_name
  ec2_tags                = merge(local.user_tag, local.ec2_tag)

  db_name           = "demodbdev"
  db_identifier     = "demodbdev"
  db_instance_class = "db.t2.micro"
  db_tags           = merge(local.user_tag, local.db_tag)

}

################################################################################
# Activate VPC peering
################################################################################
resource "aws_vpc_peering_connection" "foo" {
  peer_vpc_id = var.mgmt_vpc_id
  vpc_id      = module.myapp.vpc_id
  auto_accept = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "to" {
  route_table_id            = module.myapp.public_route_table_ids[0]
  destination_cidr_block    = var.mgmt_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo.id
}

resource "aws_route" "from" {
  route_table_id            = var.mgmt_route_table_ids[0]
  destination_cidr_block    = module.myapp.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo.id
}
