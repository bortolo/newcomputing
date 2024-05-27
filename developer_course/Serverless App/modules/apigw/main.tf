resource "aws_api_gateway_rest_api" "my_api" {
  name = var.apigw_name
  description = "API Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}

# CREATE RESOURCE

resource "aws_api_gateway_resource" "resource" {
  for_each = var.methods
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = each.value.path
}

resource "aws_api_gateway_method" "proxy" {
  for_each = var.methods
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = each.value.method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  for_each = var.methods
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.resource[each.key].id
  http_method = aws_api_gateway_method.proxy[each.key].http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = var.lambda_invoke_arn

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