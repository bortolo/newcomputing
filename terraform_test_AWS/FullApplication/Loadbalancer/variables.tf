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
