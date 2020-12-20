################################################################################
# GETTING STARTED WITH TERRAFORM LANGUAGE
# Terraform uses its own configuration language, designed to allow concise
# descriptions of infrastructure. The Terraform language is declarative,
# describing an intended goal rather than the steps to reach that goal.
# There are 5 type of terraform block in this .tf file:
#
# - provider configuration; the name given in the block header (es. "aws") is
#                           the local name of the provider to configure.
#                           This provider should already be included in a
#                           required_providers block (see versions.tf file)
#
# - locals (see the code below in this file)
#
# - data (see the code below in this file)
#
# - resource (see the code below in this file)
#
# - module (see the code below in this file)
#
# - variable (see variables.tf file)
#
# - output (see outputs.tf file)
#
# - terraform / required_providers (see versions.tf file)
#
################################################################################
provider "aws" {
  region = var.region
}

################################################################################
# - locals; a local value assigns a name to an expression, so you can use it
#           multiple times within a module without repeating it (es. local
#           variable user_tag is used many times in the code to assign tag to
#           the resources)
#
################################################################################
locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "Cloudwatch"
  }
}

################################################################################
# Create a key pair to ssh on remote EC2 host
#
# - resource; Each resource block describes one or more infrastructure objects,
#             such as virtual networks, compute instances, or higher-level
#             components such as DNS records. A resource block declares a
#             resource of a given type ("aws_key_pair") with a given local
#             name ("this"). The name is used to refer to this resource from
#             elsewhere in the same Terraform module, but has no significance
#             outside that module's scope.
#
#             Browse terraform documentation online to know what this block is
#             doing and what kind of input/output it can generate
#
#             https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
#
################################################################################
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "First_Dashboard"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "start": "-PT30M",
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics":[
               [ { "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUUtilization\"', 'Average', 1)", "id": "e1" } ]
            ],
        "period": 5,
        "stat": "Average",
        "region": "eu-central-1",
        "title": "EC2 Instance CPU"
      }
    },
    {
      "start": "-PT30M",
      "type": "metric",
      "x": 0,
      "y": 1,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics":[
               [ { "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUCreditUsage\"', 'Average', 1)", "id": "e1" } ]
            ],
        "period": 5,
        "stat": "Average",
        "region": "eu-central-1",
        "title": "EC2 Instance CPU Credit Usage"
      }
    },
    {
      "start": "-PT30M",
      "type": "metric",
      "x": 0,
      "y": 2,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics":[
               [ { "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUCreditBalance\"', 'Average', 1)", "id": "e1" } ]
            ],
        "period": 5,
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
################################################################################
# Get the aws ami metadata of and Ubuntu OS image
#
# - data; data block allows data to be fetched or computed for use elsewhere in
#         Terraform configuration. Use of data sources allows a Terraform
#         configuration to make use of information defined outside of Terraform,
#         or defined by another separate Terraform configuration.
#         For example each provider may offer data sources alongside its set of
#         resource types. In the following block we are going to get infromation
#         about aws ami owned by aws itself.
#
#         Browse terraform documentation online to know what this block is doing
#         and what kind of input/output it can generate
#
#         https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
#
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
# IAM assumable role with custom policies
################################################################################
module "iam_assumable_role_custom" {
  source            = "../../modules_AWS/terraform-aws-iam-master/modules/iam-assumable-role"
  trusted_role_arns = []
  trusted_role_services = [
    "ec2.amazonaws.com"
  ]
  create_role             = true
  create_instance_profile = true
  role_name               = var.iam_cloudwatch_logs
  role_requires_mfa       = false
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
  ]

  tags = local.user_tag
}

################################################################################
# EC2
################################################################################
################################################################################
# Create a custom VPC using the terraform module terraform-aws-vpc-master
#
# - module; a module is a container for multiple resources that are used
#           together. Every Terraform configuration has at least one module,
#           known as its root module, which consists of the resources defined
#           in the .tf files in the main working directory. A module can call
#           other modules, which lets you include the child module's resources
#           into the configuration in a concise way. Modules can also be called
#           multiple times, either within the same configuration or in separate
#           configurations, allowing resource configurations to be packaged and
#           re-used.
#
#           The label immediately after the module keyword is a local name,
#           (es. ec2) which the calling module can use to refer to this instance
#           of the module (es. module.ec2.name)
#
#           All modules require a source argument, which is a meta-argument
#           defined by Terraform. Its value is the path to a local directory
#           containing the module's configuration files (es.
#           "../../modules_AWS/terraform-aws-ec2-instance-master")
#
#           Within the block body (between { and }) are the arguments for the
#           module. Most of the arguments correspond to input variables defined
#           by the module (es. name, instance_count, ami, ...).
################################################################################
module "ec2" {
  source                      = "../../modules_AWS/terraform-aws-ec2-instance-master"
  name                        = var.ec2_name
  instance_count              = var.ec2_number_of_instances
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = var.key_pair_name
  associate_public_ip_address = var.ec2_public_ip
  monitoring                  = var.ec2_detailed_monitoring
  vpc_security_group_ids      = [module.aws_security_group.this_security_group_id]
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]
  iam_instance_profile        = var.iam_cloudwatch_logs
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

################################################################################
# Cloudwatch - Alarm
################################################################################
resource "aws_cloudwatch_metric_alarm" "foobar" {
  count                     = length(module.ec2.id) 
  alarm_name                = "half-CPUutilization-${count.index}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "50"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  dimensions = {
    InstanceId = module.ec2.id[count.index]
  }
  tags = local.user_tag
}