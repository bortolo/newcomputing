
provider "aws" {
  region = var.region
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "KindesisDataStream"
  }
}

resource "aws_kinesis_stream" "test_stream" {
  name             = var.stream_name
  shard_count      = var.number_of_shards
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = var.capacity_mode
  }

  tags = local.user_tag
}