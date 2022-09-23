
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
# VPC-A
################################################################################

resource "aws_vpc" "vpc-a" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-A"
  }
}

resource "aws_internet_gateway" "gw-a" {
  vpc_id = aws_vpc.vpc-a.id
  tags = {
    Name = "a-igw"
  }
}

# Public subent of VPC-A

resource "aws_subnet" "a-public" {
  vpc_id     = aws_vpc.vpc-a.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "a-public-subnet"
  }
}

resource "aws_route_table" "a-public" {
  vpc_id = aws_vpc.vpc-a.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-a.id
  }
    tags = {
    Name = "a-public-rt"
  }
}

resource "aws_route_table_association" "a-public" {
  subnet_id      = aws_subnet.a-public.id
  route_table_id = aws_route_table.a-public.id
}

# Private subent of VPC-A

resource "aws_subnet" "a-private" {
  vpc_id     = aws_vpc.vpc-a.id
  cidr_block = "10.0.1.0/24"
    tags = {
    Name = "a-private-subnet"
  }
}

resource "aws_route_table" "a-private" {
  vpc_id = aws_vpc.vpc-a.id
      route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id  = aws_ec2_transit_gateway.example.id
  }
    tags = {
    Name = "a-private-rt"
  }
}

resource "aws_route_table_association" "a-private" {
  subnet_id      = aws_subnet.a-private.id
  route_table_id = aws_route_table.a-private.id
}

################################################################################
# VPC-B
################################################################################

resource "aws_vpc" "vpc-b" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
    tags = {
    Name = "VPC-B"
  }
}

resource "aws_subnet" "b-private" {
  vpc_id     = aws_vpc.vpc-b.id
  cidr_block = "10.1.0.0/24"
    tags = {
    Name = "b-private-subnet"
  }
}

resource "aws_route_table" "b-private" {
  vpc_id = aws_vpc.vpc-b.id
        route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id  = aws_ec2_transit_gateway.example.id
  }
    tags = {
    Name = "b-private-rt"
  }
}

resource "aws_route_table_association" "b-private" {
  subnet_id      = aws_subnet.b-private.id
  route_table_id = aws_route_table.b-private.id
}

################################################################################
# VPC-C
################################################################################

resource "aws_vpc" "vpc-c" {
  cidr_block       = "10.2.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-C"
  }
}

resource "aws_subnet" "c-private" {
  vpc_id     = aws_vpc.vpc-c.id
  cidr_block = "10.2.0.0/24"
    tags = {
    Name = "c-private-subnet"
  }
}

resource "aws_route_table" "c-private" {
  vpc_id = aws_vpc.vpc-c.id
        route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id  = aws_ec2_transit_gateway.example.id
  }
  tags = {
    Name = "c-private-rt"
  }
}

resource "aws_route_table_association" "c-private" {
  subnet_id      = aws_subnet.c-private.id
  route_table_id = aws_route_table.c-private.id
}

################################################################################
# EC2
################################################################################

resource "aws_key_pair" "this" {
  key_name   = var.key_pair_name
  public_key = var.public_key
  tags = {
    Name = "tgway-key"
  }
}

# Jumphost

resource "aws_instance" "jumphost" {
  ami                         = "ami-0bd39c806c2335b95"
  instance_type               = "t3.micro"
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.a-public.id
  vpc_security_group_ids      = [aws_security_group.jumphost.id]
  tags = {
    Name = "Jumphost"
  }
}

resource "aws_security_group" "jumphost" {
  vpc_id      = aws_vpc.vpc-a.id
  tags = {
    Name = "jumphost"
  }
}

resource "aws_security_group_rule" "ssh-jumphost" {
  type              = "ingress"
  from_port        = 22
  to_port          = 22
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = aws_security_group.jumphost.id
}

resource "aws_security_group_rule" "all-jumphost" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.jumphost.id
}

# VM private A

resource "aws_instance" "vm-a" {
  ami                         = "ami-0bd39c806c2335b95"
  instance_type               = "t3.micro"
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.a-private.id
  vpc_security_group_ids      = [aws_security_group.vm-a.id]
  tags = {
    Name = "vm-a"
  }
}

resource "aws_security_group" "vm-a" {
  vpc_id      = aws_vpc.vpc-a.id
  tags = {
    Name = "vm-a"
  }
}

resource "aws_security_group_rule" "ssh-vm-a" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.vm-a.id
}

resource "aws_security_group_rule" "icmp-vm-a" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vm-a.id
}

resource "aws_security_group_rule" "all-vma" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.vm-a.id
}

# VM private B

resource "aws_instance" "vm-b" {
  ami                         = "ami-0bd39c806c2335b95"
  instance_type               = "t3.micro"
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.b-private.id
  vpc_security_group_ids      = [aws_security_group.vm-b.id]
  tags = {
    Name = "vm-b"
  }
}

resource "aws_security_group" "vm-b" {
  vpc_id      = aws_vpc.vpc-b.id
  tags = {
    Name = "vm-b"
  }
}

resource "aws_security_group_rule" "ssh-vm-b" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.vm-b.id
}

resource "aws_security_group_rule" "icmp-vm-b" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vm-b.id
}

# VM private C
resource "aws_instance" "vm-c" {
  ami                         = "ami-0bd39c806c2335b95"
  instance_type               = "t3.micro"
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.c-private.id
  vpc_security_group_ids      = [aws_security_group.vm-c.id]
  tags = {
    Name = "vm-c"
  }
}

resource "aws_security_group" "vm-c" {
  vpc_id      = aws_vpc.vpc-c.id
  tags = {
    Name = "vm-c"
  }
}

resource "aws_security_group_rule" "ssh-vm-c" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.vm-c.id
}

resource "aws_security_group_rule" "icmp-vm-c" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vm-c.id
}

################################################################################
# Transit gateway
################################################################################

resource "aws_ec2_transit_gateway" "example" {
  description = "example"
        tags = {
    Name = "tgway-VPC-A-B-C"
  }
}

resource "aws_ec2_transit_gateway_route_table" "example" {
  transit_gateway_id = aws_ec2_transit_gateway.example.id
          tags = {
    Name = "tgway-route-VPC-A-B-C"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc-a" {
  subnet_ids         = [aws_subnet.a-private.id]
  transit_gateway_id = aws_ec2_transit_gateway.example.id
  vpc_id             = aws_vpc.vpc-a.id
      tags = {
    Name = "attachment-a"
  }
}
/*
resource "aws_ec2_transit_gateway_route_table_association" "vpc-a" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc-a.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.example.id
}*/

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc-b" {
  subnet_ids         = [aws_subnet.b-private.id]
  transit_gateway_id = aws_ec2_transit_gateway.example.id
  vpc_id             = aws_vpc.vpc-b.id
      tags = {
    Name = "attachment-b"
  }
}
/*
resource "aws_ec2_transit_gateway_route_table_association" "vpc-b" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc-b.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.example.id
}*/

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc-c" {
  subnet_ids         = [aws_subnet.c-private.id]
  transit_gateway_id = aws_ec2_transit_gateway.example.id
  vpc_id             = aws_vpc.vpc-c.id
      tags = {
    Name = "attachment-c"
  }
}
/*
resource "aws_ec2_transit_gateway_route_table_association" "vpc-c" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc-c.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.example.id
}
*/
