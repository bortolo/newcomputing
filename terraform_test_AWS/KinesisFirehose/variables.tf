variable "region" {
  description = "(Required) The AWS region that you want to use"
  type = string
}

variable "awsusername" {
  description = "(Required) Aws username"
  type = string
}

################################################################################
# Kinesis Firehose variables
################################################################################

variable "deliverystream_name" {
  description = "(Required) Name of the Kinesis Firehose delivery stream"
  type = string
}

variable "buffer_size" {
  description = "(Required) Buffer size of the Kinesis Firehose delivery stream (min: 1MB / MAX: 128MB)"
  type = number
}

variable "buffer_interval" {
  description = "(Required) Buffer interval of the Kinesis Firehose delivery stream (min: 60s / MAX: 900s)"
  type = number
}

################################################################################
# S3 bucket variables
################################################################################

variable "bucket_name" {
  description = "(Required) Name of the S3 bucket used as destination by Kinesis Firehose"
  type = string
}
