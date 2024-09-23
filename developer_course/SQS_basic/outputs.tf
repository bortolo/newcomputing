output sqs_arn {
    value = aws_sqs_queue.terraform_queue.arn
}

output s3_arn {
    value = aws_s3_bucket.example.arn
}