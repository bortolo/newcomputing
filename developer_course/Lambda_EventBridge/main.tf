locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-lambda-eventbridge"
  }
}
resource "aws_iam_role" "lambda_role" {
name                = "MyTest_Lambda_Function_Role"
assume_role_policy  = file("./resources/lambda_role.json")
tags = local.tags
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy       = file("./resources/lambda_policy.json")
  tags = local.tags

}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

# Asynch invokation (update region and function name)
# aws lambda invoke --function-name Lambda_developercourse-lambda-asynch_v01 --cli-binary-format raw-in-base64-out --payload '{"key1": "value1", "key2": "value2", "key3": "value3" }' --invocation-type Event --region eu-central-1 response.json

resource "aws_lambda_function" "terraform_lambda_func" {
filename                       = "./resources/hello-python-v${var.code_version}.zip"
function_name                  = "Lambda_${local.tags.Name}_v${var.code_version}"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index${var.code_version}.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]

tags = local.tags
}


resource "aws_lambda_permission" "with_eventbridge" {
  statement_id  = "AllowExecutionFrom_eventbridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.eventbridge_rule_arns.crons
}

module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  rules = {
    crons = {
      description         = "Trigger for a Lambda"
      schedule_expression = "rate(1 minute)"
    }
  }

  targets = {
    crons = [
      {
        name  = "lambda-loves-cron"
        arn   = aws_lambda_function.terraform_lambda_func.arn
        input = jsonencode({"job": "cron-by-rate"})
      }
    ]
  }
}