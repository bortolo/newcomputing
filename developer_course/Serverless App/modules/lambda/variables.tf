variable "function_name" {
  type    = string
  default = ""
}

variable "environmental_variables" {
  type = map(string)
}

variable "tags"{
  type = map(string)
}

variable "aws_region" {
  type    = string
}