variable "awsusername" {
  description = "(Required) Aws username"
}

variable "db_username" {
  description = "(Required) db username"
}

variable "db_password" {
  description = "(Required) db password"
}

variable "db_private_dns" {
  description = "(Required) db private dns name"
}

variable "db_secret_name" {
  description = "(Required) db secret name for AWS SecretsManager"
}

variable "iam_role_name" {
  description = "(Required) IAM role name for the custom policy of EC2 instances running nodejs and accessing AWS SecretsManager"
}

variable "key_pair_name" {
  description = "(Required) The key pair name to log in EC2 instances"
}
