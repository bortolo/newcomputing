locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-kds-basic"
  }
}

# Nice comparison Kinesis vs Kafka
# https://www.softwareag.com/en_corporate/blog/streamsets/kafka-vs-kinesis.html#


resource "aws_kinesis_stream" "test_stream" {
  name             = "terraform-kinesis-test"
  shard_count      = 1
  #retention_period = 48

/*
  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
*/

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = local.tags
}