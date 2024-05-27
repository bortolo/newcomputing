variable "apigw_name" {
  type    = string
}

variable "methods" {
  type    = map(map(string))
}

variable "tags"{
  type = map(string)
}

variable "aws_region" {
  type    = string
}

variable lambda_invoke_arn {
  type = string
}