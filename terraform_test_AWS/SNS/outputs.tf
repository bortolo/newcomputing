output "main_SNS_topic" {
    description = "The ARN of the main SNS topic"
    value = aws_sns_topic.main.arn
}