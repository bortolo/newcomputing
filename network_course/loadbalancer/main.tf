locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Environment = "network-course"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-iac"
  cidr = var.network_structure["cidr"][0]

  azs             = var.network_structure["azs"]
  public_subnets  = var.network_structure["public"]
  private_subnets = var.network_structure["private"]

  enable_ipv6        = false
  enable_nat_gateway = false
  single_nat_gateway = false

  public_subnet_tags = local.tags
  private_subnet_tags = local.tags

  vpc_tags = {
    Name = "vpc-iac"
    Owner       = "andrea.bortolossi"
    Environment = "all"
  }
}