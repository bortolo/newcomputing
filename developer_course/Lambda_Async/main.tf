locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-lambda-asynch"
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

dead_letter_config {
  target_arn = aws_sqs_queue.terraform_queue.arn
}

tags = local.tags
}

resource "aws_lambda_function_event_invoke_config" "example" {
  function_name                = aws_lambda_function.terraform_lambda_func.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 2
}

resource "aws_sqs_queue" "terraform_queue" {
  name                      = "lambda_dlq"
  tags = local.tags
}