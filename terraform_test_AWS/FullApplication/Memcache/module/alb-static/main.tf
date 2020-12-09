
################################################################################
# Data sources to create custom VPC and custom subnets (public and database)
################################################################################
module "vpc" {
  source = "../../../../../modules_AWS/terraform-aws-vpc-master"
  name   = var.vpc_name
  cidr   = var.vpc_cidr
  azs    = var.vpc_azs
  public_subnets = var.vpc_public_subnets
  public_subnet_tags = {
    subnet_type = "public"
  }
  private_subnets = var.vpc_private_subnets
  private_subnet_tags = {
    subnet_type = "private"
  }
  enable_dhcp_options      = true
  dhcp_options_domain_name = "eu-central-1.compute.internal"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.vpc_tags
}

##################################################################
# Application Load Balancer
##################################################################
module "alb" {
  source = "../../../../../modules_AWS/terraform-aws-alb-master"

  name                 = var.alb_name
  load_balancer_type   = "application"
  vpc_id               = module.vpc.vpc_id
  security_groups      = [module.aws_security_group_ALB.this_security_group_id]
  subnets              = module.vpc.public_subnets

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]
  target_groups = [
  {
    name_prefix          = "h1"
    backend_protocol     = "HTTP"
    backend_port         = 8080
    target_type          = "instance"
    deregistration_delay = 10
    health_check = {
      enabled             = true
      interval            = 30
      path                = "/"
      port                = "traffic-port"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      timeout             = 6
      protocol            = "HTTP"
      matcher             = "200-399"
    }
    // tags = {
    //   InstanceTargetGroupTag = "baz"
    // }
  },
  ]

  tags = var.alb_tags
}

module "aws_security_group_ALB" {
  source      = "../../../../../modules_AWS/terraform-aws-security-group-master"
  name        = "ALB_security_group"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
  egress_rules        = ["all-all"]

  tags = var.alb_tags
}

resource "aws_lb_target_group_attachment" "test" {
  count            = length(module.ec2_FE.id)
  target_group_arn = module.alb.target_group_arns[0]
  target_id        = module.ec2_FE.id[count.index]
}

################################################################################
# EC2
################################################################################
module "ec2_FE" {
  source                      = "../../../../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = var.ec2_name
  instance_count              = var.ec2_number_of_instances
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_pair_name
  associate_public_ip_address = var.ec2_public_ip
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group_FE.this_security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  // iam_instance_profile        = var.ec2_iam_role_name //it is highly dependent on terraform custom module
  user_data                   = var.ec2_user_data

  tags = var.ec2_tags
}

module "aws_security_group_FE" {
  source      = "../../../../../modules_AWS/terraform-aws-security-group-master"
  name        = "FE_security_group"
  description = "Security group for front-end servers"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "Service name"
      source_security_group_id = module.aws_security_group_ALB.this_security_group_id
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

  tags = var.ec2_tags
}

################################################################################
# memcache
################################################################################
module "memcached" {
  source                  = "../../../../../modules_AWS/terraform-aws-elasticache-memcached-master"
  name                    = var.mem_name
  availability_zones      = var.mem_azs
  vpc_id                  = module.vpc.vpc_id
  allowed_security_groups = [module.aws_security_group_FE.this_security_group_id]
  subnets                 = module.vpc.private_subnets
  cluster_size            = var.mem_cluster_size
  instance_type           = var.mem_instance_type
  engine_version          = var.mem_engine_version
  apply_immediately       = true
  tags                    = var.mem_tags

}
