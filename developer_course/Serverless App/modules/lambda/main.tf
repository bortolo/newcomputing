resource "aws_iam_role" "lambda_role" {
name                = "${var.function_name}_function_role"
assume_role_policy  = file("./resources/${var.function_name}/lambda_role.json")
tags = var.tags
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name         = "aws_iam_policy_for_terraform_aws_lambda_role_${var.function_name}"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy       = file("./resources/${var.function_name}/lambda_policy.json")
  tags = var.tags

}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${var.apigw_arn}/*/*/*"
}

resource "aws_lambda_function" "function" {
filename                       = "./resources/${var.function_name}/${var.function_name}.zip"
function_name                  = "${var.function_name}"
role                           = aws_iam_role.lambda_role.arn
handler                        = "${var.function_name}.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]

environment {
    variables = var.environmental_variables
}
tags = var.tags
}