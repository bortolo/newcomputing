
provider "aws" {
  region = var.region
}

locals {

  user_tag = {
    Owner = var.awsusername
    Test  = "TransitGateway-01"
  }
}



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
  //source                      = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"
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
  user_data                   = data.cloudinit_config.example.rendered
  iam_instance_profile        = module.iam_assumable_role_custom.iam_instance_profile_name

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

module "iam_assumable_role_custom" {
  source            = "github.com/terraform-aws-modules/terraform-aws-iam/modules/iam-assumable-role"
  trusted_role_arns = []
  trusted_role_services = [
    "ec2.amazonaws.com"
  ]
  create_role             = true
  create_instance_profile = true
  role_name               = "ec2-admin-firehose"
  role_requires_mfa       = false
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
  ]

  tags = local.user_tag
}

data "cloudinit_config" "example" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
    content      = <<-END
      #cloud-config
      ${jsonencode({
        write_files = [
          {
            path        = "/etc/aws-kinesis/agent.json"
            permissions = "0644"
            owner       = "root:root"
            encoding    = "b64"
            content     = filebase64("./resources/agent.json")
          },
                    {
            path        = "/home/ec2-user/.aws/config"
            permissions = "0644"
            owner       = "root:root"
            encoding    = "b64"
            content     = filebase64("./resources/config")
          },
        ]
      })}
    END
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "example.sh"
    content      = file("./resources/EC2_userdata")
  }
}

################################################################################
# KINESI DATA STREAM
################################################################################

resource "aws_kinesis_stream" "test_stream" {
  name             = var.stream_name
  shard_count      = var.number_of_shards
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = var.capacity_mode
  }

  tags = local.user_tag
}

################################################################################
# DYNAMO DB
################################################################################

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "CadabraOrders"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "CustomerID"
  range_key      = "OrderID"

   attribute {
    name = "CustomerID"
    type = "N"
  }

  attribute {
    name = "OrderID"
    type = "S"
  }

  tags = local.user_tag
}

################################################################################
# LAMBDA
################################################################################

resource "aws_lambda_function" "test_lambda" {
  filename      = "./resources/lambda-function01.zip"
  function_name = "ProcessOrders"
  role          = module.iam_assumable_role_lambda.iam_role_arn
  handler       = "lambda-function.lambda_handler"
  source_code_hash = filebase64sha256("./resources/lambda-function01.zip")

  runtime = "python3.9"
}

module "iam_assumable_role_lambda" {
  source            = "github.com/terraform-aws-modules/terraform-aws-iam/modules/iam-assumable-role"
  trusted_role_arns = []
  trusted_role_services = [
    "lambda.amazonaws.com"
  ]
  create_role             = true
  create_instance_profile = false
  role_name               = "lambda-process-orders"
  role_requires_mfa       = false
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
  ]

  tags = local.user_tag
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn  = aws_kinesis_stream.test_stream.arn
  function_name     = aws_lambda_function.test_lambda.arn
  starting_position = "LATEST"
}