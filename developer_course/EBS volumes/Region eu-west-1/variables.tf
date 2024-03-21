variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "network_structure" {
  type = map(any)
  default = {
    cidr    = ["10.0.0.0/16"]
    azs     = ["eu-west-1a","eu-west-1b"]
    public  = ["10.0.1.0/24","10.0.2.0/24"]
    private = ["10.0.11.0/24","10.0.12.0/24"]
  }
}