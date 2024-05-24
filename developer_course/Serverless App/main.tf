locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-serverless-app"
  }
}

#####################################################################################
# INSERT USER
#####################################################################################

resource "aws_iam_role" "lambda_role_insertuser" {
name                = "MyTest_Lambda_Function_Role"
assume_role_policy  = file("./resources/InsertUser/lambda_role.json")
tags = local.tags
}

resource "aws_iam_policy" "iam_policy_for_lambda_insertuser" {
  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy       = file("./resources/InsertUser/lambda_policy.json")
  tags = local.tags

}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role_insertuser" {
 role        = aws_iam_role.lambda_role_insertuser.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda_insertuser.arn
}

# If you want to upload a new versione of the function
# 1) cd /resources/InsertUser
# 2) . ./create_packages.sh
# 3) terraform destroy -target aws_lambda_function.InsertUser
# 4) terraform apply

resource "aws_lambda_function" "InsertUser" {
filename                       = "./resources/InsertUser/InsertUser.zip"
function_name                  = "InsertUser"
role                           = aws_iam_role.lambda_role_insertuser.arn
handler                        = "InsertUser.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_insertuser]

environment {
    variables = {
      ListOfUsers_table = aws_dynamodb_table.ListOfUsers.name
  }
}
tags = local.tags
}

#####################################################################################
# GET USERS
#####################################################################################

resource "aws_iam_role" "lambda_role_getusers" {
name                = "Lambda_Function_Role_getusers"
assume_role_policy  = file("./resources/GetUsers/lambda_role.json")
tags = local.tags
}

resource "aws_iam_policy" "iam_policy_for_lambda_getusers" {
  name         = "aws_iam_policy_for_terraform_aws_lambda_role_getusers"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy       = file("./resources/GetUsers/lambda_policy.json")
  tags = local.tags

}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role_getusers" {
 role        = aws_iam_role.lambda_role_getusers.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda_getusers.arn
}

# If you want to upload a new versione of the function
# 1) cd /resources/GetUsers
# 2) . ./create_packages.sh
# 3) terraform destroy -target aws_lambda_function.GetUsers
# 4) terraform apply

resource "aws_lambda_function" "GetUsers" {
filename                       = "./resources/GetUsers/GetUsers.zip"
function_name                  = "GetUsers"
role                           = aws_iam_role.lambda_role_getusers.arn
handler                        = "GetUsers.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_getusers]

environment {
    variables = {
      ListOfUsers_table = aws_dynamodb_table.ListOfUsers.name
  }
}
tags = local.tags
}

#####################################################################################
# LIST OF USERS DYNAMO DB TABLE
#####################################################################################

resource "aws_dynamodb_table" "ListOfUsers" {
  name           = "ListOfUsers"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }

  tags = local.tags
}