#######################################################################################
# EC2 in ASG with ALB
#######################################################################################

# Crea il ruolo IAM per ECS task
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = [
          "ecs.amazonaws.com", #questo serve? o serve solo il tasks?
          "ecs-tasks.amazonaws.com"
          #"application-autoscaling.amazonaws.com"
          ]
      }
    }]
  })

    tags = local.tags
}

# Attacca policy al ruolo di EC2
resource "aws_iam_role_policy" "ec2_policy" {
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "*",
        Resource = "*"
      }
    ]
  })
}