variable "awsusername" {
  description = "(Required) Aws username"
}

variable "key_pair_name" {
  description = "(Required) The key pair name to log in EC2 instances"
}

variable "ssh_public_key" {
  description = "(Required) The public key to associate with the key pair to log in EC2 instances"
}
