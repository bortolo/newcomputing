variable "region" {
  description = "(Required) The AWS region that you want to use"
  type = string
}

variable "awsusername" {
  description = "(Required) Aws username"
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