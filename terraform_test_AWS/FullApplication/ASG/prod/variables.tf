variable "awsusername" {
  description = "(Required) Aws username"
  type        = string
}

################################################################################
# Variables to use AMI image
################################################################################
variable "AMI_name" {
  description = "(Required) The name of the AMI (creat_AMI must be set to true to create the AMI)"
  type        = string
}

################################################################################
# Variable to create the app infrastructure
################################################################################
variable "key_pair_name" {
  description = "(Required) The key pair name to log in EC2 instances"
  type        = string
}

variable "ec2_user_data" {
  description = "(Required) The commands to run when EC2 instances are launched"
  type        = string
}

variable "asg_min_size" {
  description = "(Required) The minimum number of EC2 instances in the ASG"
  type        = string
}

variable "asg_max_size" {
  description = "(Required) The maximum number of EC2 instances in the ASG"
  type        = string
}

variable "asg_desired_capacity" {
  description = "(Required) The desired number of EC2 instances in the ASG"
  type        = string
}
