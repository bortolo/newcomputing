variable "awsusername" {
  description = "(Required) Aws username"
}

variable "region" {
  description = "(Required) The AWS region that you want to use"
  type = string
}

variable "public_key" {
  description = "(Required) The id_RSA public key"
  type = string
}

variable "ec2_ami_id" {
  description = "(Required) The AMI id to use for EC2 instance"
  type = string
  default = ""
 }

 variable "ec2_NAT_ami_id" {
  description = "(Required) The AMI id to use for NAT EC2 instance"
  type = string
  default = ""
 }

variable "nat_instance_or_gateway" {
  description = "True if you want to use NAT instancve, False if you want to use NAT gateway"
  type = bool
  default = true
}