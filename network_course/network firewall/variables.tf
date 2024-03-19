variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "network_structure" {
  type = map(any)
  default = {
    cidr    = ["10.0.0.0/16"]
    azs     = ["eu-central-1a"]
    public  = ["10.0.1.0/24","10.0.2.0/24"]
    public_subnet_names = ["fw-sub","web-sub"]
    private  = []
    private_subnet_names = []
  }
}