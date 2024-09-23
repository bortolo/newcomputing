locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-sqs-basic"
  }
}


resource "aws_sqs_queue" "terraform_queue" {
  name                        = "terraform-example-queue"
  
  # Configuration
  visibility_timeout_seconds  = 5
  message_retention_seconds   = 86400
  delay_seconds               = 0
  max_message_size            = 262144 #bytes
  receive_wait_time_seconds   = 0

  # Encryption
  sqs_managed_sse_enabled     = false

  # Access policy
  policy = file("./resources/SQS_policy.json")

  # Dead Letter Queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_dlq.arn
    maxReceiveCount     = 3
  })

  # Tags
  tags = local.tags
}

resource "aws_s3_bucket" "example" {
  bucket = "my-bucket-${local.tags.Name}"
  tags = local.tags
}

# Update the SQS_policy.json file with the right SQS arn, S3 arn and source account ID 
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.example.id

  queue {
    queue_arn     = aws_sqs_queue.terraform_queue.arn
    events        = ["s3:ObjectCreated:*"]
  }
}


resource "aws_sqs_queue" "terraform_queue_dlq" {
  name                        = "terraform-example-queue-dlq"
  
  # Configuration
  visibility_timeout_seconds  = 30
  message_retention_seconds   = 1209600
  delay_seconds               = 0
  max_message_size            = 262144 #bytes
  receive_wait_time_seconds   = 0

  # Encryption
  sqs_managed_sse_enabled     = false

  # Access policy
  # policy = file("./resources/SQS_policy.json")

  /*redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount     = 4
  })*/

  # Tags
  tags = local.tags
}