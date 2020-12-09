module "vpc" {
  source = "../../modules_AWS/terraform-aws-vpc-master"

  name = "complete-example"

  cidr = "10.0.0.0/16"

  azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  private_subnets = ["10.0.0.0/21", "10.0.16.0/21", "10.0.32.0/21"]
  private_subnet_tags = {
    subnet_type = "private"
  }

  public_subnets = ["10.0.48.0/21", "10.0.64.0/21", "10.0.80.0/21"]
  public_subnet_tags = {
    subnet_type = "public"
  }

  database_subnets = ["10.0.96.0/21", "10.0.112.0/21", "10.0.128.0/21"]
  database_subnet_tags = {
    subnet_type = "database"
  }

  create_database_subnet_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_classiclink             = false
  enable_classiclink_dns_support = false

  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  enable_vpn_gateway  = false
  enable_dhcp_options = true

  tags = local.user_tag
}
