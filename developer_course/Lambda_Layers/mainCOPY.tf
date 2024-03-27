locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-lambda-RDS"
  }
}


/*
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

# to get the right arn you can manually deploy the lambda fucntion and then pick it up from the lambda console
layers           = ["arn:aws:lambda:eu-central-1:292169987271:layer:AWSLambda-Python38-SciPy1x:107"]

tags = local.tags
}
*/

resource "aws_kms_key" "example" {
  description = "Example KMS Key"
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "postgres"
  engine_version       = "16.1"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"

  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.example.key_id
}