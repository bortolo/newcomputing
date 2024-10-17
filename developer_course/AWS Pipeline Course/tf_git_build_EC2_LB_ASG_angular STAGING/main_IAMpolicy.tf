#######################################################################################
# EC2 in ASG with ALB
#######################################################################################

# Crea il ruolo IAM per EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.webserver_name}_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

    tags = local.tags
}

# Attacca policy al ruolo di EC2
resource "aws_iam_role_policy" "ec2_policy" {
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ],
        Resource = [
          "*"
        ]
      },
      {
      "Action": [
        "codedeploy-commands-secure:*",
        "codedeploy:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
    ]
  })
}

# creazione instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.webserver_name}_instance_profile"
  role = aws_iam_role.ec2_role.name
}