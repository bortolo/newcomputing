
provider "aws" {
  region = var.region
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "KindesisFirehose"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = var.deliverystream_name
  destination = "extended_s3"
    extended_s3_configuration {
    role_arn        = aws_iam_role.firehose_role.arn
    bucket_arn      = aws_s3_bucket.bucket.arn
    buffer_size     = var.buffer_size
    buffer_interval = var.buffer_interval
  }
  tags    = local.user_tag
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  tags   = local.user_tag
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_test_role"
  assume_role_policy = file("./resources/Policy_Firehose.json")
}