variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "pipeline_name" {
  type    = string
}

variable "codebuild_name" {
  type    = string
}

variable "github_repo" {
  type    = string
}

variable "github_connection_name" {
  type    = string
}