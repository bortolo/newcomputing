locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-lambda-SQSeventmapping"
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


resource "aws_lambda_function" "terraform_lambda_func" {
filename                       = "./resources/hello-python-v${var.code_version}.zip"
function_name                  = "Lambda_${local.tags.Name}_v${var.code_version}"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index${var.code_version}.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]

tags = local.tags
}

resource "aws_sqs_queue" "terraform_queue" {
  name                      = "lambda_sqs"
  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.terraform_queue.arn
  enabled          = true
  function_name    = "${aws_lambda_function.terraform_lambda_func.arn}"
  batch_size       = 1
}