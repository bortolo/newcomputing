provider "aws" {
  region = var.region
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "SNS"
  }
}

resource "aws_sns_topic" "main" {
  name = "my-first-topic"
  
  tags = local.user_tag
}