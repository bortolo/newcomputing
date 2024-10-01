variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

# Definizione di una variabile per l'OAuth token GitHub
variable "github_oauth_token" {
  type      = string
  sensitive = true
}
