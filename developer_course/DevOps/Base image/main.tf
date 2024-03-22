locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Environment = "developer-course"
  }
}

# Use default VPC and subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}



module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "MySecurityGroupforbaseimage"
  description = "Security group for base image creation"
  vpc_id      = data.aws_vpc.default.id

  rules = {
    # Jenkins
    jenkins-8080-tcp  = [8080, 8080, "tcp", "Jenkins 8080"]
    jenkins-8085-tcp  = [8085, 8085, "tcp", "Jenkins 8085"]
    # SSH and others
    all-all           = [-1, -1, "-1", "All protocols"]
    ssh-tcp           = [22, 22, "tcp", "SSH"]
    all-icmp          = [-1, -1, "icmp", "All IPV4 ICMP"]
  }

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp","all-icmp","jenkins-8080-tcp","jenkins-8085-tcp"]
  egress_rules        = ["all-all"]

}

resource "aws_key_pair" "this" {
  key_name   = "ec2-key-pair-base-image"
  public_key = file("./resources/id_rsa.pub")
}

# When the server is up and running ssh into it and get the Jenkins password
# sudo cat /var/lib/jenkins/secrets/initialAdminPassword
# zagron-mIznu5-hyrxij

module "baseimage" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                        = "BaseImage"
  ami                         = "ami-023adaba598e661ac"
  instance_type               = "t2.micro"
  availability_zone           = element(["eu-central-1c"], 0)
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true
  key_name                    = "ec2-key-pair-base-image"

  user_data_base64            = base64encode(file("./resources/userdata.txt"))
  user_data_replace_on_change = true

  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = false
      volume_type = "gp2"
      volume_size = 8
      tags = {
        Name = "my-root-block"
      }
    },
  ]

    tags = local.tags

}

resource "aws_ami_from_instance" "example" {
  name               = "BaseImageAMI"
  source_instance_id = module.baseimage.id
}