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

  azs                 = var.network_structure["azs"]
  
  public_subnets      = var.network_structure["public"]
  public_subnet_names = var.network_structure["public_subnet_names"]

  private_subnets       = var.network_structure["private"]
  private_subnet_names  = var.network_structure["private_subnet_names"]

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

module "security_group_web" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "security-group-web-server"
  description = "Security group for webserver instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp","all-icmp","http-80-tcp"]
  egress_rules        = ["all-all"]

}

resource "aws_key_pair" "this" {
  key_name   = "ec2-key-pair"
  public_key = file("./resources/id_rsa.pub")
}



module "ec2-web" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                        = "ec2-iac-tool"
  ami                         = "ami-0a261c0e5f51090b1"
  instance_type               = "t2.micro"
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 1)
  vpc_security_group_ids      = [module.security_group_web.security_group_id]
  associate_public_ip_address = true
  key_name                    = "ec2-key-pair"

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  user_data_base64            = base64encode(file("./resources/userdata.txt"))
  user_data_replace_on_change = true

  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 50
      tags = {
        Name = "my-root-block"
      }
    },
  ]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = 5
      throughput  = 200
      encrypted   = false
    }
  ]

    tags = local.tags

}
/*

resource "aws_networkfirewall_rule_group" "example" {
  capacity = 100
  name     = "demo-stateless"
  type     = "STATELESS"
}

resource "aws_networkfirewall_rule_group" "drop_icmp" {
  capacity = 1
  name     = "drop-icmp"
  type     = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [1]
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
}

TO DO
https://github.com/aws-samples/aws-network-firewall-terraform/blob/main/firewall.tf

resource "aws_networkfirewall_firewall_policy" "example" {
  name = "deny-icmp"
  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:drop"]
    stateless_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.example.arn
    }
  }
}

resource "aws_networkfirewall_firewall" "example" {
  name                = "example"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.example.arn
  vpc_id              = aws_vpc.example.id
  subnet_mapping {
    subnet_id = aws_subnet.example.id
  }

  tags = {
    Tag1 = "Value1"
    Tag2 = "Value2"
  }
}
*/