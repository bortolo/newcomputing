provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner       = var.awsusername
    Test        = "ASG"
    Environment = "prod"
  }
  ec2_tag = {server_type = "fe_server"}
}

################################################################################
# Select which AMI to use
################################################################################
data "aws_ami" "app_ami" {
  owners      = ["152371567679"]
  most_recent = true
  filter {
    name   = "name"
    values = [var.AMI_name]
  }
}

################################################################################
# Create the app infrastructure (dynamic infra with ASG)
################################################################################
module "myapp" {
  source = "../module/alb-asg"

  vpc_name             = "vpc-prod"
  vpc_cidr             = "10.0.0.0/16"
  vpc_azs              = ["eu-central-1a","eu-central-1b"]
  vpc_public_subnets   = ["10.0.8.0/21","10.0.16.0/21"]
  vpc_tags             = local.user_tag

  alb_name = "alb-prod"
  alb_tags = local.user_tag

  ec2_name                = "fe_server-prod"
  ec2_ami_id              = data.aws_ami.app_ami.id
  ec2_instance_type       = "t2.micro"
  ec2_key_pair_name       = var.key_pair_name
  ec2_public_ip           = false //TODO DB doesn't work with public_ip set to false
  ec2_user_data           = var.ec2_user_data

  asg_min_size            = var.asg_min_size
  asg_max_size            = var.asg_max_size
  asg_desired_capacity    = var.asg_desired_capacity

  ec2_tags          = merge(local.user_tag, local.ec2_tag)
}
