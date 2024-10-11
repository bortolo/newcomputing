variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "lambda_name" {
  type    = string
  default = "my_lambda_function"
}

variable "bucket_name" {
  type    = string
  default = "my-codepipeline-bucket-developercourse-experiments-3"
}

variable "codebuild_name" {
  type    = string
}

variable "github_url" {
  type    = string
}

variable "test_alias" {
  type    = string
}

variable "github_repo" {
  type    = string
}

variable "github_connection_name" {
  type    = string
}