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
  apigw_arn = aws_api_gateway_rest_api.my_api.execution_arn
}

module "lambda_getusers" {
  source = "./modules/lambda"
  function_name = "GetUsers"
  environmental_variables = {ListOfUsers_table = aws_dynamodb_table.ListOfUsers.name}
  tags = local.tags
  aws_region = var.aws_region
  apigw_arn = aws_api_gateway_rest_api.my_api.execution_arn
}

module "lambda_APIuser" {
  source = "./modules/lambda"
  function_name = "API_user"
  environmental_variables = {ListOfUsers_table = aws_dynamodb_table.ListOfUsers.name}
  tags = local.tags
  aws_region = var.aws_region
  apigw_arn = aws_api_gateway_rest_api.my_api.execution_arn
}

#####################################################################################
# LIST OF USERS - DYNAMO DB TABLE
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

#####################################################################################
# API gateway
#####################################################################################

resource "aws_api_gateway_rest_api" "my_api" {
  name = "my-api"
  description = "My API Gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = local.tags
}

output APIgateway {
    value = aws_api_gateway_rest_api.my_api.execution_arn
}
# CREATE RESOURCE

resource "aws_api_gateway_resource" "status" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "status"
}

# CREATE METHODS

# GET

resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = module.lambda_APIuser.invoke_arn

}

resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"

}

resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.lambda_integration
  ]
}

# DEPLOY

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    #aws_api_gateway_integration.options_integration, # Add this line
  ]

  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name = "dev"
}