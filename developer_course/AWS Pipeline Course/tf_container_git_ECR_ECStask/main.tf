locals {
  tags = {
    Owner = "andrea.bortolossi"
    Name  = "AWS-course-codepipeline-ecs"
  }
  deployment_tag = "MyAngularProject-ecs"
}

# INFO DA AGGIORNARE
# Tempo creazione del laboratorio: 3m 30s OK
# Tempo di esecuzione delle pipeline applicativa: 4m 43s
#   0m 3s  source
#   2m 36s build
#   2m 4s deploy 

resource "aws_ecs_task_definition" "service" {
  family       = "my-angular-task-definition"
  network_mode = "awsvpc"

  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  #App environment
  requires_compatibilities = ["FARGATE"]

  #Task size
  cpu    = 256
  memory = 512

  runtime_platform {
    #Operating system/architecture
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  # fare riferimento alla guida per configurazione task
  # https://docs.aws.amazon.com/it_it/AmazonECS/latest/developerguide/task_definition_parameters.html
  container_definitions = jsonencode([
    {
      name  = "angular-app"
      image = "152371567679.dkr.ecr.eu-central-1.amazonaws.com/my-angular-app:latest" #da rendere dinamico
      portMappings = [
        {
          containerPort = 80
        }
      ]
    }
  ])
}

# GUARDA QUESTA GUIDA
# https://spacelift.io/blog/terraform-ecs

# get the default vpc resources
resource "aws_default_vpc" "default" {
}
resource "aws_default_subnet" "default_az1" {
  availability_zone = "eu-central-1a"
}
resource "aws_default_subnet" "default_az2" {
  availability_zone = "eu-central-1b"
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster-angular-app"
}

resource "aws_ecs_cluster_capacity_providers" "my_providers" {
  cluster_name = aws_ecs_cluster.my_cluster.name

  capacity_providers = ["FARGATE"] #,"EC2"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# TODO - autoscaling group for EC2 instances


resource "aws_ecs_service" "my_service" {
  name            = "my-rolling-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 2

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # Enable to force a new task deployment of the service. 
  # This can be used to update tasks to use a newer Docker image with 
  # same image/tag combination (e.g., myimage:latest), roll Fargate tasks 
  # onto a newer platform version, or immediately deploy ordered_placement_strategy 
  # and placement_constraints updates
  force_new_deployment = true

  # Redeploy Service On Every Apply
  # triggers = {
  #  redeployment = timestamp()
  #}

  # TODO Non può andare in contrasto con il task definition ???
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }

  network_configuration {
    subnets          = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group_for_alb.arn
    container_name   = "angular-app"
    container_port   = 80
  }

  deployment_circuit_breaker {
    enable = true
    rollback = true
  }

}


# Application loadbalancer to put in front of the ECS services
resource "aws_lb" "my_app_loadbalancer" {
  name                       = "my-rolling-service-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [module.security_group_alb.security_group_id]
  subnets                    = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  enable_deletion_protection = false

  tags = local.tags
}

# Security group per ALB
module "security_group_alb" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "security-group-alb"
  description = "Security group for application load balancer"
  vpc_id      = aws_default_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "all-icmp", "http-80-tcp"]
  egress_rules        = ["all-all"]

}

# Target group per ALB
resource "aws_lb_target_group" "my_target_group_for_alb" {
  name        = "my-rolling-service-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default.id

  # To speedup the deployment phase
  deregistration_delay = 30

  health_check {
    path = "/"
  }
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
