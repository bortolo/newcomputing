variable "awsusername" {
  description = "(Required) Aws username"
  type = string
  validation {
    condition     = var.awsusername != "<your-user-name>"
    error_message = "You must to set your own AWS username."
  }
}

variable "db_username" {
  description = "(Required) db username"
  validation {
    condition     = var.db_username != "<admin-user-for-db>"
    error_message = "You must to set your own db username (don't push your secret in a git repository)."
  }
}

variable "db_password" {
  description = "(Required) db password"
  validation {
    condition     = var.db_password != "<password-for-db>"
    error_message = "You must to set your own db password (don't push your secret in a git repository)."
  }
}
