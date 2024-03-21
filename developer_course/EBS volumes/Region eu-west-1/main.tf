###################
# Per vedere la lista dei volumi montati e le carratteristiche
# df -aTh
# Per vedere la lista di tutti i volumi (anche non montati)
# sudo fdisk -l
# lsblk
# sudo parted -l
#
# mkdir -p /mnt/ebs_volume --> Creare cartella di mount del volume
# mkfs -t ext4 /dev/xvdf --> Formattare volume per poterlo montare
# mount /dev/xvdf /mnt/ebs_volume --> Montare il volume formattato
###################

locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Environment = "developer-course"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-first-webserver"
  cidr = var.network_structure["cidr"][0]

  azs             = var.network_structure["azs"]
  public_subnets  = var.network_structure["public"]
  private_subnets = var.network_structure["private"]

  enable_ipv6        = false
  enable_nat_gateway = false
  single_nat_gateway = false

  public_subnet_tags = local.tags
  private_subnet_tags = local.tags

  vpc_tags = {
    Name        = "vpc-first-webserver"
    Owner       = "andrea.bortolossi"
    Environment = "all"
  }
}

module "security_group_web" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "security-group-web-server"
  description = "Security group for webserver instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp","all-icmp","http-80-tcp"]
  egress_rules        = ["all-all"]

}

resource "aws_key_pair" "this" {
  key_name   = "ec2-key-pair"
  public_key = file("./resources/id_rsa.pub")
}

module "webserver" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                        = "webserver"
  ami                         = "ami-074254c177d57d640"
  instance_type               = "t2.micro"
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group_web.security_group_id]
  associate_public_ip_address = true
  key_name                    = "ec2-key-pair"

  user_data_base64            = base64encode(file("./resources/userdata.txt"))
  user_data_replace_on_change = true

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }


  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = false
      volume_type = "gp2"
      volume_size = 8
      tags        = { Name = "my-root-block"}
    },
  ]

 ebs_block_device = [
    {
      device_name = "/dev/sdf" #Attenzione: questo nome può cambiare /dev/xvdf
      volume_type = "gp3"
      volume_size = 10
      encrypted   = false
      tags        = { 
                      Name     = "myvolume"
                      Snapshot = "true"
                      }
    }
  ]

    tags = local.tags

}


data "aws_ebs_volume" "ebs_volume" {
  most_recent = true
  filter {
    name   = "tag:Name"
    values = ["myvolume"]
  }
}


resource "aws_ebs_snapshot" "example_snapshot" {
  volume_id = data.aws_ebs_volume.ebs_volume.id

  tags = {
    Name = "HelloWorld_snap01"
  }
}

########################
# AWS Data Lifecycle Mgmt
###########

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name               = "dlm-lifecycle-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "dlm_lifecycle" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name   = "dlm-lifecycle-policy"
  role   = aws_iam_role.dlm_lifecycle_role.id
  policy = data.aws_iam_policy_document.dlm_lifecycle.json
}

resource "aws_dlm_lifecycle_policy" "example" {
  description        = "example DLM lifecycle policy"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "2 days of hourly snapshots"

      create_rule {
        interval      = 1
        interval_unit = "HOURS"
        times         = ["10:50"]
      }

      retain_rule {
        count = 2
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = false
    }

    target_tags = {
      Snapshot = "true"
    }
  }
}
