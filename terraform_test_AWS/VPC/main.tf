
################################################################################
# GETTING STARTED WITH TERRAFORM LANGUAGE
# Terraform uses its own configuration language, designed to allow concise
# descriptions of infrastructure. The Terraform language is declarative,
# describing an intended goal rather than the steps to reach that goal.
# There are 5 type of terraform block in this .tf file:
#
# - provider configuration; the name given in the block header (es. "aws") is
#                           the local name of the provider to configure.
#                           This provider should already be included in a
#                           required_providers block (see versions.tf file)
#
# - locals (see the code below in this file)
#
# - data (see the code below in this file)
#
# - resource (see the code below in this file)
#
# - module (see the code below in this file)
#
# - variable (see variables.tf file)
#
# - output (see outputs.tf file)
#
# - terraform / required_providers (see versions.tf file)
#
################################################################################
provider "aws" {
  region = "eu-central-1"
}

################################################################################
# - locals; a local value assigns a name to an expression, so you can use it
#           multiple times within a module without repeating it (es. local
#           variable user_tag is used many times in the code to assign tag to
#           the resources)
#
################################################################################
locals {
  user_tag = {
    # Here you can see how to use a variable defined in variable.tf
    # file var.<name-of-the-variable>
    Owner = var.awsusername
    Test  = "VPC"
  }
  ec2_tag_public         = { server_type = "public" }
  ec2_tag_private        = { server_type = "private" }
  ec2_tag_database       = { server_type = "database" }
  security_group_tag_ec2 = { scope = "security_server" }
}


################################################################################
# Get the aws ami metadata of and Ubuntu OS image
#
# - data; data block allows data to be fetched or computed for use elsewhere in
#         Terraform configuration. Use of data sources allows a Terraform
#         configuration to make use of information defined outside of Terraform,
#         or defined by another separate Terraform configuration.
#         For example each provider may offer data sources alongside its set of
#         resource types. In the following block we are going to get infromation
#         about aws ami owned by aws itself.
#
#         Browse terraform documentation online to know what this block is doing
#         and what kind of input/output it can generate
#
#         https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
#
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
# Create a key pair to ssh on remote EC2 host
#
# - resource; Each resource block describes one or more infrastructure objects,
#             such as virtual networks, compute instances, or higher-level
#             components such as DNS records. A resource block declares a
#             resource of a given type ("aws_key_pair") with a given local
#             name ("this"). The name is used to refer to this resource from
#             elsewhere in the same Terraform module, but has no significance
#             outside that module's scope.
#
#             Browse terraform documentation online to know what this block is
#             doing and what kind of input/output it can generate
#
#             https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
#
################################################################################
resource "aws_key_pair" "this" {
  key_name   = "${local.user_tag.Owner}${local.user_tag.Test}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCVPI+y9VK/2KhV0kNH1boKE3xTkVIo57fWX1qf8+AR4uu+IIr1sM4LLWcbhTR4WY8okfzv9LoCl/LWg30ODsbLuYX2heamZOuSg5CyFSJj6i2RgS2M2wppKLo13+tEqUm4c4E6dnVk2YHeDs7A5asL1IUGnqvcpey2+ZMTgCEa6nfqxitSl3wWSuMZpNUTXtnQh/3Yp1dMlHjdUuiUCHEKIPyHdz2mF/i6yEf4RPLFWVKpX+o1TpfnoVlFipiobcqiZ0SOOgJsbqWGrykrdnYbvOYtKBpNF3OSTZdBaxRHtH907ykre+9gqTPnQFqq3hncUNQuQvpiv9SlZyuCVmr5 andreabortolossi@Andreas-MBP.lan"

  tags = local.user_tag
}

################################################################################
# Create a custom VPC using the terraform module terraform-aws-vpc-master
#
# - module; a module is a container for multiple resources that are used
#           together. Every Terraform configuration has at least one module,
#           known as its root module, which consists of the resources defined
#           in the .tf files in the main working directory. A module can call
#           other modules, which lets you include the child module's resources
#           into the configuration in a concise way. Modules can also be called
#           multiple times, either within the same configuration or in separate
#           configurations, allowing resource configurations to be packaged and
#           re-used.
#
#           The label immediately after the module keyword is a local name,
#           (es. vpc) which the calling module can use to refer to this instance
#           of the module (es. module.vpc.vpc_id)
#
#           All modules require a source argument, which is a meta-argument
#           defined by Terraform. Its value is the path to a local directory
#           containing the module's configuration files (es.
#           "../../modules_AWS/terraform-aws-vpc-master")
#
#           Within the block body (between { and }) are the arguments for the
#           module. Most of the arguments correspond to input variables defined
#           by the module (es. name, cidr, azs, ...).
################################################################################
module "vpc" {
  source = "../../modules_AWS/terraform-aws-vpc-master"

  name = "complete-example"
  cidr = "10.0.0.0/16"
  azs  = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  public_subnets     = ["10.0.48.0/21", "10.0.64.0/21", "10.0.80.0/21"]
  public_subnet_tags = { subnet_type = "public" }

  private_subnets     = ["10.0.0.0/21", "10.0.16.0/21", "10.0.32.0/21"]
  private_subnet_tags = { subnet_type = "private" }

  database_subnets     = ["10.0.96.0/21", "10.0.112.0/21", "10.0.128.0/21"]
  database_subnet_tags = { subnet_type = "database" }

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_dhcp_options  = true

  create_database_subnet_group   = false
  enable_classiclink             = false
  enable_classiclink_dns_support = false
  enable_nat_gateway             = false
  single_nat_gateway             = false
  one_nat_gateway_per_az         = false
  enable_vpn_gateway             = false

  tags = local.user_tag
}

################################################################################
# Create Route53 host zone
#
# Here again we are using the "resource" terraform block to create a route53
# hosted zone. Hosted zone should be associated to a VPC to well resolve DNS
# names. To assign the vpc we need the id and we can get it from the vpc module
# that we created before.
#
################################################################################
resource "aws_route53_zone" "private" {
  name = "private_host_zone"
  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = local.user_tag
}

################################################################################
# Create DNS record for private EC2 instance
#
# We are using the resource block to create a route53 record.
# The record must be added to a host zone. We choose the host zone created within
# this .tf file (aws_route53_zone.private.zone_id).
# The friendly name ("private.example.com") is associated with the private ip
# address of the ec2 that we are going to create later in the code
# (module.ec2_private.private_ip[0])
#
################################################################################
resource "aws_route53_record" "private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "private.example.com"
  type    = "A"
  ttl     = "300"
  records = [module.ec2_private.private_ip[0]]
}

################################################################################
# Create DNS record for database EC2 instance
#
# Here we are adding the DNS record for the EC2 instance database. Same as the
# previous resource but we are calling the other ec2 instance
# (module.ec2_database.private_ip[0])
#
################################################################################
resource "aws_route53_record" "database" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "database.example.com"
  type    = "A"
  ttl     = "300"
  records = [module.ec2_database.private_ip[0]]
}

################################################################################
# Create an EC2 instances using the terraform module terraform-aws-ec2-instance-master
#
# We are using a different module to create an ec2 instance. To set several
# variables we are using many references to resources or modules created in this
# .tf file:
# - data.aws_ami.ubuntu.id; ami id got from AWS
# - aws_key_pair.this.key_name; created with our id_rsa.pub
# - module.aws_security_group_server.this_security_group_id; security group created later in the code
# - tolist(module.vpc.public_subnets)[0]; associate the first public subnet of the VPC
################################################################################
module "ec2_public" {
  source = "../../modules_AWS/terraform-aws-ec2-instance-master"

  name                        = "public_server"
  instance_count              = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_id                   = tolist(module.vpc.public_subnets)[0]

  tags = merge(local.user_tag, local.ec2_tag_public)
}

################################################################################
# Create an EC2 instances using the terraform module terraform-aws-ec2-instance-master
#
# We are using the same module as before but we are deploying a new EC2
# instance on the private subnet of the first azs
# - tolist(module.vpc.private_subnets)[0]
#
################################################################################
module "ec2_private" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "private_server"
  instance_count              = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_id                   = tolist(module.vpc.private_subnets)[0]

  tags = merge(local.user_tag, local.ec2_tag_private)
}

################################################################################
# Create an EC2 instances using the terraform module terraform-aws-ec2-instance-master
#
# We are using the same module as before but we are deploying a new EC2
# instance on the database subnet of the first azs
# - tolist(module.vpc.database_subnets)[0]
#
################################################################################
module "ec2_database" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = "database_server"
  instance_count              = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true //use this feature only for test/dev purposes
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_server.this_security_group_id]
  subnet_id                   = tolist(module.vpc.database_subnets)[0]

  tags = merge(local.user_tag, local.ec2_tag_database)
}

################################################################################
# Create a security group using the terraform module terraform-aws-security-group-master
#
# We are using a different module to create a security group. We have to assign
# the security group to a vpc (module.vpc.vpc_id) and we are defining some useful
# rules for inbound and outbound trafic.
#
################################################################################
module "aws_security_group_server" {
  source      = "../../modules_AWS/terraform-aws-security-group-master"
  name        = "server_security_group"
  description = "Security group for servers"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
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
