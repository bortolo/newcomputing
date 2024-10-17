variable "aws_region" {
  type    = string
  default = "eu-central-1"
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

variable "unit_test_buildspec_name" {
  type    = string
}

variable "apply_staging_buildspec_name" {
  type    = string
}

variable "destroy_staging_buildspec_name" {
  type    = string
}

variable "webserver_name" {
  type    = string
}

variable "network_structure" {
  type = map(any)
  default = {
    cidr    = ["10.0.0.0/16"]
    azs     = ["eu-central-1a","eu-central-1b"]
    public  = ["10.0.1.0/24","10.0.2.0/24"]
    private = ["10.0.11.0/24"]
  }
}

variable "application_name" {
  type    = string
}

variable "codedeploy_name" {
  type    = string
}