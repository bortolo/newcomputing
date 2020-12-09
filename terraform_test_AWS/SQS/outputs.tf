output "main_SQS_url" {
    description = "The URL of the main SQS queue"
    value = aws_sqs_queue.main.id
}