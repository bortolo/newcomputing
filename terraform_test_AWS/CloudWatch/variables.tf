variable "region" {
  description = "(Required) The AWS region that you want to use"
  type = string
}

variable "awsusername" {
  description = "(Required) Aws username"
  type = string
}

variable "key_pair_name" {
  description = "(Required) The key pair name to log in EC2 instances"
    type = string
}

variable "public_key" {
  description = "(Required) The id_RSA public key"
  type = string
}

################################################################################
# IAM variables
################################################################################
variable "iam_cloudwatch_logs" {
  description = "(Required) The name of the IAM role"
  type = string
}

################################################################################
# EC2 variables
################################################################################
variable "ec2_name" {
  description = "(Required) The EC2 name"
  type = string
}

variable "ec2_number_of_instances" {
  description = "(Required) The number of EC2 instances to deploy"
  type = string
}

variable "ec2_ami_id" {
  description = "(Required) The AMI id to use for EC2 instance"
  type = string
  default = ""
 }

variable "ec2_instance_type" {
  description = "(Required) The type of EC2 instance"
  type = string
}

variable "ec2_key_pair_name" {
  description = "(Required) The key pair name to log in EC2 instances"
  type = string
  default = ""
}

variable "ec2_public_ip" {
  description = "(Required) If true deploy EC2 instances with public ip available"
  type = bool
}

variable "ec2_iam_role_name" {
  description = "(Required) IAM role name for the custom policy of EC2 instances running nodejs and accessing AWS SecretsManager"
  type = string
  default = ""
}

variable "ec2_user_data" {
  description = "The user data to provide when launching the instance. Do not pass gzip-compressed data via this argument; see user_data_base64 instead."
  type        = string
  default     = null
}

variable "ec2_tags" {
  description = "A map of tags to add to EC2 resources"
  type        = map(string)
  default     = {}
}