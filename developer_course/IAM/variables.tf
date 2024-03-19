variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "users" {
  type    = list(string)
  default = [
              "Carlo",
              "Giulia",
              "Mario"
              ]
}

variable "groups_and_users" {
  type    = map(list(string))
  default = {
    Developers   = [
                    "Carlo",
                    "Mario"
                    ]
    Audit        = [
                    "Giulia",
                    "Mario"
                    ]
    Operations    = [
                    "Carlo"
                    ]
  }
}