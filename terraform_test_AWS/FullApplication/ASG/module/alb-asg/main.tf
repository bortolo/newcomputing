
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
  name        = "ALB_security_group-${var.alb_name}"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
  egress_rules        = ["all-all"]

  tags = var.alb_tags
}

################################################################################
# EC2 wit ASG
################################################################################
module "asg_prod" {
  source = "../../../../../modules_AWS/terraform-aws-autoscaling-master"

  name = "asg-prod-${var.ec2_name}"

  # Launch configuration
  #
  # launch_configuration = "my-existing-launch-configuration" # Use the existing launch configuration
  # create_lc = false # disables creation of launch configuration
  lc_name = "lc-${var.ec2_name}"

  image_id                     = var.ec2_ami_id
  instance_type                = var.ec2_instance_type
  security_groups              = [module.aws_security_group_FE.this_security_group_id]
  associate_public_ip_address  = var.ec2_public_ip
  key_name                     = var.ec2_key_pair_name
  recreate_asg_when_lc_changes = true
  target_group_arns            = [module.alb.target_group_arns[0]]

  user_data                    = var.ec2_user_data

  # Auto scaling group
  asg_name                  = "asg-${var.ec2_name}"
  vpc_zone_identifier       = module.vpc.public_subnets
  health_check_type         = "EC2"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  wait_for_capacity_timeout = 0
  // service_linked_role_arn   = aws_iam_service_linked_role.autoscaling.arn

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
