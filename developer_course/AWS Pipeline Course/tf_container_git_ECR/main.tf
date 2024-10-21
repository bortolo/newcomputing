locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "AWS-course-codepipeline-ecs"
  }
  deployment_tag = "MyAngularProject-ecs"
}

# INFO DA AGGIORNARE
# Tempo creazione del laboratorio: 3m 30s
# Tempo di esecuzione delle pipeline applicativa: 5m 11s
#   0m 3s  source
#   3m 4s  unit test
#   1m 32s build
#   xm xxs staging (manual approve minimo - ricordarsi di approvare subscription)
#   0m 32s deploy 

/*
resource "aws_ecs_cluster" "example" {
  name = "my-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.example.name

  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_ecs_service" "mongo" {
  name            = "mongodb"
  cluster         = aws_ecs_cluster.foo.id
  task_definition = aws_ecs_task_definition.mongo.arn
  desired_count   = 3
  iam_role        = aws_iam_role.foo.arn
  depends_on      = [aws_iam_role_policy.foo]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.foo.arn
    container_name   = "mongo"
    container_port   = 8080
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}
*/