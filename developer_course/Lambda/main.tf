locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-lambda"
  }
}
resource "aws_iam_role" "lambda_role" {
name   = "Spacelift_Test_Lambda_Function_Role"
assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
tags = local.tags
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
 
 name         = "aws_iam_policy_for_terraform_aws_lambda_role"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
tags = local.tags
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

# Launch this command, update the version as variables.tf
# cd ./resources
# json
# zip -r hello-python-v01.zip index01.py
# html
# zip -r hello-python-v02.zip index02.py
#
# From terraform launch this command
# terraform apply -var="code_version=01
# or
# terraform apply -var="code_version=02

resource "aws_lambda_function" "terraform_lambda_func" {
filename                       = "./resources/hello-python-v${var.code_version}.zip"
function_name                  = "Lambda_Function_Demo_v${var.code_version}"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index${var.code_version}.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
tags = local.tags
}

####################################################################################
# APPLICATION LOADBALANCER
####################################################################################

resource "aws_lambda_permission" "with_lb" {
  statement_id  = "AllowExecutionFromlb"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.front_end.arn
}

# Use default VPC and subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Use custom security group
module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = local.tags.Name
  description = "Security group for ${local.tags.Name}"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags

}

# Define loadbalancer, target group and listener
resource "aws_lb" "front_end" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security_group.security_group_id]
  subnets            = data.aws_subnets.default.ids

  tags = local.tags
}

resource "aws_lb_target_group" "front_end" {
  name        = "tf-example-lb-tg"
  target_type = "lambda"
  tags = local.tags
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
  tags = local.tags
}

# Attach lambda function to the target group
resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.front_end.arn
  target_id        = aws_lambda_function.terraform_lambda_func.arn
  depends_on       = [aws_lambda_permission.with_lb]                    #[IMPORTANT] give the right permission to lambda
}