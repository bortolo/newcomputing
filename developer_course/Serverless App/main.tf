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

module "lambda_APIuser" {
  source = "./modules/lambda"
  function_name = "API_user"
  environmental_variables = {ListOfUsers_table = aws_dynamodb_table.ListOfUsers.name}
  tags = local.tags
  aws_region = var.aws_region
  apigw_arn = module.myapgw.APIgateway
}

#####################################################################################
# LIST OF USERS - DYNAMO DB TABLE
#####################################################################################

resource "aws_dynamodb_table" "ListOfUsers" {
  name           = "ListOfUsers"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "employeeid"

  attribute {
    name = "employeeid"
    type = "S"
  }

  tags = local.tags
}

#####################################################################################
# API gateway
#####################################################################################

module myapgw {
  source = "./modules/apigw"
  apigw_name = "FirstApp"
  tags = local.tags
  aws_region = var.aws_region
  lambda_invoke_arn = module.lambda_APIuser.invoke_arn
  methods = {
    status_GET = {path="status",method="GET"},
    employee_GET = {path="employee",method="GET"},
    employee_POST = {path="employee",method="POST"},
    employee_PATCH = {path="employee",method="PATCH"},
    employee_DELETE = {path="employee",method="DELETE"},
    employees_GET = {path="employees",method="GET"}
  }
}