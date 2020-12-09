provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner       = var.awsusername
    Test        = "ASG"
    Environment = "cross"
  }
}

################################################################################
# Key pair name for the EC2 instances
################################################################################
resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = var.ssh_public_key

  tags = local.user_tag
}
