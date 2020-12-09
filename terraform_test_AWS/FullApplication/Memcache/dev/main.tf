provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner       = var.awsusername
    Test        = "MEMCACHE"
    Environment = "dev"
  }
  ec2_tag = {
    server_type = "fe_server"
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
# Create the app infrastructure (stati infra without ASG)
################################################################################
module "myapp" {
  source = "../module/alb-static"

  vpc_name             = "custom-dev"
  vpc_cidr             = "10.0.0.0/16"
  vpc_azs              = ["eu-central-1a","eu-central-1b"]
  vpc_public_subnets   = ["10.0.8.0/21","10.0.16.0/21"]
  vpc_private_subnets   = ["10.0.24.0/21"]

  vpc_tags             = local.user_tag

  alb_name = "alb-dev"
  alb_tags = local.user_tag

  ec2_name                = "fe_server-dev"
  ec2_number_of_instances = 2
  ec2_ami_id              = data.aws_ami.ubuntu.id
  ec2_instance_type       = "t2.micro"
  ec2_key_pair_name       = var.key_pair_name
  ec2_public_ip           = true
  ec2_tags                = merge(local.user_tag, local.ec2_tag)

  mem_name                = "memcache-dev"
  mem_azs                 = ["eu-central-1a"]
  mem_instance_type       = "cache.t3.micro"
  mem_engine_version      = "1.5.16"
  mem_cluster_size        = 1
  mem_tags                = local.user_tag

}
