
provider "aws" {
  region = var.region
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "KindesisFirehose"
  }
}
/*
resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = var.deliverystream_name
  destination = "extended_s3"
    extended_s3_configuration {
    role_arn        = aws_iam_role.firehose_role.arn
    bucket_arn      = aws_s3_bucket.bucket.arn
    buffer_size     = var.buffer_size
    buffer_interval = var.buffer_interval
  }
  tags    = local.user_tag
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  tags   = local.user_tag
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_test_role"
  assume_role_policy = file("./resources/Policy_Firehose.json")
}
*/

################################################################################
# EC2
################################################################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = var.public_key
  tags = local.user_tag
}

module "ec2" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = var.ec2_name
  instance_count              = 1
  ami                         = "ami-0bd39c806c2335b95" //AWS Linux AMI
  instance_type               = "t2.micro"
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group.security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]
  user_data                   = file("./resources/EC2_userdata")

  tags = local.user_tag
}

module "aws_security_group" {
  source      = "github.com/terraform-aws-modules/terraform-aws-security-group"
  name        = "security_group"
  description = "Security group for Kinesis"
  vpc_id      = data.aws_vpc.default.id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "allow all outbound"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = local.user_tag
}