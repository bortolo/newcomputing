variable "region" {
  description = "(Required) The AWS region that you want to use"
  type = string
}

variable "awsusername" {
  description = "(Required) Aws username"
  type = string
}

################################################################################
# Kinesis Data Stream variables
################################################################################

variable "stream_name" {
  description = "(Required) Name of the Kinesis Data Stream"
  type = string
}

variable "capacity_mode" {
  description = "(Required) Capacity mode of the Kinesis Data Stream (ON_DEMAND/PROVISIONED)"
  type = string
}

variable "number_of_shards" {
  description = "(Required) Number of shards used by the Kinesis Data Stream"
  type = number
  default = 1
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

################################################################################
# EC2 variables
################################################################################

variable "key_pair_name" {
  description = "(Required) The key pair name to log in EC2 instances"
    type = string
}

variable "public_key" {
  description = "(Required) The id_RSA public key"
  type = string
}

variable "ec2_name" {
  description = "(Required) The EC2 name"
  type = string
}