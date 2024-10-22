variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "ecr_buildspec_name" {
  type = string
}
variable application_name {
  type    = string
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