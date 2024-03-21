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
  ami                         = "ami-01be94ae58414ab2e"
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
      tags = {
        Name = "my-root-block"
      }
    },
  ]

 ebs_block_device = [
    {
      device_name = "/dev/sdf" #Attenzione: questo nome può cambiare /dev/xvdf
      volume_type = "gp3"
      volume_size = 10
      encrypted   = false
    }
  ]

    tags = local.tags

}