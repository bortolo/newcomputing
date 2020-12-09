################################################################################
# VPC variables
################################################################################
variable "vpc_name" {
  description = "(Required) The VPC name (must be unique)"
  type = string
}

variable "vpc_cidr" {
  description = "(Required) The VPC cidr block"
  type = string
}

variable "vpc_azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "vpc_public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "vpc_database_subnets" {
  description = "A list of database subnets"
  type        = list(string)
  default     = []
}

variable "vpc_tags" {
  description = "A map of tags to add to VPC resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Network Load Balancer variables
################################################################################
variable "alb_name" {
  description = "(Required) The Application Load Balancer name (must be unique)"
  type = string
}

variable "alb_tags" {
  description = "A map of tags to add to ALB resources"
  type        = map(string)
  default     = {}
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
}

variable "ec2_instance_type" {
  description = "(Required) The type of EC2 instance"
  type = string
}

variable "ec2_key_pair_name" {
  description = "(Required) The key pair name to log in EC2 instances"
  type = string
}

variable "ec2_public_ip" {
  description = "(Required) If true deploy EC2 instances with public ip available"
  type = bool
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
