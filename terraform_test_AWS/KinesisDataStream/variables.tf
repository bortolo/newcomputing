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