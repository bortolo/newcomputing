locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Environment = "developer-course"
  }
}

resource "aws_iam_policy" "jenkins_server_policy" {
  name        = "jenkins_server_policy"
  path        = "/"
  description = "My jenkins server policy"
  policy = file("./resources/jenkins_server_policy.json")
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-first-webserver"
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
    Name        = "vpc-first-webserver"
    Owner       = "andrea.bortolossi"
    Environment = "all"
  }
}

module "security_group_web" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "MySecurityGroupJenkinsServer"
  description = "Security group for Jenkins server"
  vpc_id      = module.vpc.vpc_id

  rules = {
    # Jenkins
    jenkins-8080-tcp  = [8080, 8080, "tcp", "Jenkins 8080"]
    jenkins-8085-tcp  = [8085, 8085, "tcp", "Jenkins 8085"]
    # SSH and others
    all-all           = [-1, -1, "-1", "All protocols"]
    ssh-tcp           = [22, 22, "tcp", "SSH"]
    all-icmp          = [-1, -1, "icmp", "All IPV4 ICMP"]
  }

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp","all-icmp","jenkins-8080-tcp","jenkins-8085-tcp"]
  egress_rules        = ["all-all"]

}

resource "aws_key_pair" "this" {
  key_name   = "ec2-key-pair"
  public_key = file("./resources/id_rsa.pub")
}

module "webserver" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                        = "JenkinsServerInstance"
  ami                         = "ami-064573ac645743ea8" #WARNING: using AMI v2 beacause amazon-linux-extras does not exist on v2023
  instance_type               = "t2.micro"
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group_web.security_group_id]
  associate_public_ip_address = true
  key_name                    = "ec2-key-pair"

  user_data_base64            = base64encode(file("./resources/userdata.txt"))
  user_data_replace_on_change = true

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for Jenkins server instance"
  iam_role_policies = {
    jenkins_server_policy = aws_iam_policy.jenkins_server_policy.arn
  }

  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = false
      volume_type = "gp2"
      volume_size = 8
      tags = {
        Name = "my-root-block"
      }
    },
  ]

    tags = local.tags

}
