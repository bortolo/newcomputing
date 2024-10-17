locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "AWS-course-codepipeline"
  }
  deployment_tag = "MyAngularProject-staging"
}

# INFO DA AGGIORNARE
# Tempo creazione del laboratorio: 3m 30s (la parte più lunga la prende il ALB)
# Tempo di esecuzione delle pipeline applicativa: 5m 11s
#   0m 3s  source
#   3m 4s  unit test
#   1m 32s build
#   0m 32s deploy 


# Definizione VPC custom
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

# Segurity group per webserver prod
module "security_group_web" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "security-group-web-server"
  description = "Security group for webserver instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp","all-icmp","http-80-tcp","https-443-tcp"]
  egress_rules        = ["all-all"]

}

# Key pair per webserver prod
resource "aws_key_pair" "this" {
  key_name   = "ec2-key-pair"
  public_key = file("./resources/id_rsa.pub")
}

/*
# Launch template for ASG
resource "aws_launch_template" "webserver_template" {
  name = "web-server-template"
  description = "A prod web server for my angular sample app"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  image_id = "ami-003475c38636343f5" # must be created before!!!
  instance_type = "t2.micro"
  key_name = "ec2-key-pair"
  vpc_security_group_ids = [module.security_group_web.security_group_id]
}

# ASG configuration
resource "aws_autoscaling_group" "webserver_asg" {
  name                      = "tf-my-asg"
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 2
  vpc_zone_identifier       = [element(module.vpc.public_subnets, 0),element(module.vpc.public_subnets, 1)]
  target_group_arns         = [aws_lb_target_group.my_target_group_for_alb.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 1800 #just to allow the pipeline execution, not in real life

  launch_template {
    id      = aws_launch_template.webserver_template.id
    version = "$Latest"
  }
}

# Application loadbalancer to put in front of the ASG
resource "aws_lb" "my_app_loadbalancer" {
  name               = "my-alb-angular-app"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security_group_alb.security_group_id]
  subnets            = [element(module.vpc.public_subnets, 0),element(module.vpc.public_subnets, 1)]
  #subnets            = [for subnet in module.vpc.public_subnets : subnet.vpc_id]
  enable_deletion_protection = false

  tags = local.tags
}

# Security group per ALB
module "security_group_alb" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "security-group-alb"
  description = "Security group for application load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp","all-icmp","http-80-tcp"]
  egress_rules        = ["all-all"]

}

# Target group per ALB
resource "aws_lb_target_group" "my_target_group_for_alb" {
  name                 = "tf--alb-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 60
}

# Listener rule per ALB
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my_app_loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group_for_alb.arn
  }
}
*/