provider "aws" {
  region = var.region
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "SQS"
  }
}

resource "aws_sqs_queue" "main" {
  name                        = "main-SQS-queue"
  delay_seconds               = 0
  max_message_size            = 262144
  message_retention_seconds   = 345600
  visibility_timeout_seconds  = 30
  receive_wait_time_seconds   = 0
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter.arn
    maxReceiveCount     = 4
  })

  tags = local.user_tag
}

resource "aws_sqs_queue" "deadletter" {
  name                        = "deadletter-SQS-queue"
  delay_seconds               = 0
  max_message_size            = 262144
  message_retention_seconds   = 345600
  visibility_timeout_seconds  = 30
  receive_wait_time_seconds   = 0

  tags = local.user_tag
}
