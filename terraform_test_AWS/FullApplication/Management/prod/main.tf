provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner       = var.awsusername
    Test        = "AMI"
    Environment = "prod"
  }
  ec2_tag = {
    server_type = "fe_server"
  }
  db_tag = {
    type = "prod_db"
  }
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
# Create the app infrastructure
################################################################################
module "myapp" {
  source = "../module"

  db_secret_name = var.db_secret_name

  vpc_name             = "custom-prod"
  vpc_cidr             = "10.0.0.0/16"
  vpc_azs              = ["eu-central-1a", "eu-central-1b"]
  vpc_public_subnets   = ["10.0.8.0/21"]
  vpc_database_subnets = ["10.0.16.0/21", "10.0.24.0/21"]
  vpc_tags             = local.user_tag

  route53_tags = local.user_tag

  nlb_name = "nlb-prod"
  nlb_tags = local.user_tag

  ec2_name                = "fe_server-prod"
  ec2_number_of_instances = 3
  ec2_ami_id              = data.aws_ami.app_ami.id
  ec2_instance_type       = "t2.micro"
  ec2_key_pair_name       = var.key_pair_name
  ec2_public_ip           = true //TODO DB doesn't work with public_ip set to false

  ec2_iam_role_name = var.iam_role_name
  ec2_user_data     = <<EOF
                              #!/bin/bash
                              systemctl restart nodejs"
                              EOF
  ec2_tags          = merge(local.user_tag, local.ec2_tag)

  db_name           = "demodbprod"
  db_identifier     = "demodbprod"
  db_instance_class = "db.t2.micro"
  db_tags           = merge(local.user_tag, local.db_tag)

}
