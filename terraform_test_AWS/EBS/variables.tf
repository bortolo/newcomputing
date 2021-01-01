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

variable "ec2_t_instance" {
  description = "Deploy instance with size t2.micro (required if you want to test different EBS volumes)"
  type = bool
  default = true
}

variable "ec2_i_instance" {
  description = "Deploy instance with size i3.large (required if you want to test performance storage directly attached)"
  type = bool
  default = false
}

################################################################################
# standard
################################################################################
variable "standard_create"{
  description = "True if you want to create the disk volume"
  type = bool
  default = true
}

variable "standard_size"{
  description = "Size of the disk volume"
  type = number
  default = 16
}

variable "standard_device_name"{
  description = "Name of the disk device"
  type = string
  default = "/dev/sdf"
}

################################################################################
# gp2
################################################################################
variable "gp2_create"{
  description = "True if you want to create the disk volume"
  type = bool
  default = true
}

variable "gp2_size"{
  description = "Size of the disk volume"
  type = number
  default = 16
}

variable "gp2_device_name"{
  description = "Name of the disk device"
  type = string
  default = "/dev/sdg"
}

################################################################################
# io1
################################################################################
variable "io1_create"{
  description = "True if you want to create the disk volume"
  type = bool
  default = true
}

variable "io1_size"{
  description = "Size of the disk volume"
  type = number
  default = 32
}

variable "io1_iops"{
  description = "IOPS of the disk volume"
  type = number
  default = 1600 //Iops to volume size maximum ratio is 50
}

variable "io1_device_name"{
  description = "Name of the disk device"
  type = string
  default = "/dev/sdh"
}

################################################################################
# io2
################################################################################
variable "io2_create"{
  description = "True if you want to create the disk volume"
  type = bool
  default = true
}

variable "io2_size"{
  description = "Size of the disk volume"
  type = number
  default = 128
}

variable "io2_iops"{
  description = "IOPS of the disk volume"
  type = number
  default = 6400 //Iops to volume size maximum ratio is 50
}

variable "io2_device_name"{
  description = "Name of the disk device"
  type = string
  default = "/dev/sdi"
}

################################################################################
# sc1
################################################################################
variable "sc1_create"{
  description = "True if you want to create the disk volume"
  type = bool
  default = true
}
variable "sc1_size"{
  description = "Size of the disk volume"
  type = number
  default = 500
}

variable "sc1_device_name"{
  description = "Name of the disk device"
  type = string
  default = "/dev/sdl"
}

################################################################################
# st1
################################################################################
variable "st1_create"{
  description = "True if you want to create the disk volume"
  type = bool
  default = true
}

variable "st1_size"{
  description = "Size of the disk volume"
  type = number
  default = 500
}

variable "st1_device_name"{
  description = "Name of the disk device"
  type = string
  default = "/dev/sdm"
}