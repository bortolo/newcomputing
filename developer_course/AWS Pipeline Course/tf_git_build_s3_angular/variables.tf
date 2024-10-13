variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "bucket_prod" {
  type    = string
  default = "my-codepipeline-bucket-developercourse-experiments-3"
}

variable "pipeline_name" {
  type    = string
}

variable "github_repo" {
  type    = string
}

variable "github_connection_name" {
  type    = string
}

variable "codebuild_name" {
  type    = string
}