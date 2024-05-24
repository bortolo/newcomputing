locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-serverless-app"
  }
}


#####################################################################################
# LAMBDA FUNCTIONS
#####################################################################################

# If you want to upload a new version of the function
# 1) cd /resources/<function_name>
# 2) . ./create_packages.sh
# 3) terraform destroy -target module.lambda_<function_name>
# 4) terraform apply

module "lambda_insertuser" {
  source = "./modules/lambda"
  function_name = "InsertUser"
  environmental_variables = {ListOfUsers_table = aws_dynamodb_table.ListOfUsers.name}
  tags = local.tags
  aws_region = var.aws_region
}

module "lambda_getusers" {
  source = "./modules/lambda"
  function_name = "GetUsers"
  environmental_variables = {ListOfUsers_table = aws_dynamodb_table.ListOfUsers.name}
  tags = local.tags
  aws_region = var.aws_region
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