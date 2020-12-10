provider "aws" {
  region = var.region
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "Cloudwatch"
  }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "First_Dashboard"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "start": "-PT1H",
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics":[
               [ { "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUUtilization\"', 'Average', 300)", "id": "e1" } ]
            ],
        "period": 300,
        "stat": "Average",
        "region": "eu-central-1",
        "title": "EC2 Instance CPU"
      }
    },
    {
      "start": "-PT1H",
      "type": "metric",
      "x": 0,
      "y": 1,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics":[
               [ { "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUCreditUsage\"', 'Average', 300)", "id": "e1" } ]
            ],
        "period": 300,
        "stat": "Average",
        "region": "eu-central-1",
        "title": "EC2 Instance CPU Credit Usage"
      }
    },
    {
      "start": "-PT1H",
      "type": "metric",
      "x": 0,
      "y": 2,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics":[
               [ { "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUCreditBalance\"', 'Average', 300)", "id": "e1" } ]
            ],
        "period": 300,
        "stat": "Average",
        "region": "eu-central-1",
        "title": "EC2 Instance CPU Credit Balance"
      }
    }
  ]
}
EOF
}

################################################################################
# Data sources to get VPC, subnets and security group details
################################################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

################################################################################
# Key pair name for the EC2 instances
################################################################################
resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = var.public_key

  tags = local.user_tag
}

################################################################################
# EC2
################################################################################
module "ec2" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = var.ec2_name
  instance_count              = var.ec2_number_of_instances
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = var.key_pair_name
  associate_public_ip_address = var.ec2_public_ip
  monitoring                  = false
  vpc_security_group_ids      = [module.aws_security_group.this_security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]
  //iam_instance_profile        = var.ec2_iam_role_name //it is highly dependent on terraform custom module
  //user_data                   = var.ec2_user_data

  tags = local.user_tag
}

module "aws_security_group" {
  source      = "../../modules_AWS/terraform-aws-security-group-master"
  name        = "FE_security_group"
  description = "Security group for front-end servers"
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