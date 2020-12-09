
/****  standard EBS  ****/
/*
resource "aws_ebs_volume" "standard" {
  availability_zone = "eu-central-1a"
  size              = 1
  type              = "standard"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_standard" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.standard.id
  instance_id = module.ec2_public.id[0]
}
*/
/****  gp2 EBS  ****/
/*
resource "aws_ebs_volume" "gp2" {
  availability_zone = "eu-central-1a"
  size              = 1
  type              = "gp2"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_gp2" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.gp2.id
  instance_id = module.ec2_public.id[0]
}
*/
/****  io1 EBS  ****/
/*
resource "aws_ebs_volume" "io1" {
  availability_zone = "eu-central-1a"
  size              = 16
  type              = "io1"
  iops              = 800 //Iops to volume size maximum ratio is 50

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_io1" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.io1.id
  instance_id = module.ec2_public.id[0]
}
*/
/****  io2 EBS  ****/
/*
resource "aws_ebs_volume" "io2" {
  availability_zone = "eu-central-1a"
  size              = 16
  type              = "io2"
  iops              = 800 //Iops to volume size maximum ratio is 50

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_io2" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.io2.id
  instance_id = module.ec2_public.id[0]
}
*/
/****  sc1 EBS  ****/
/*
resource "aws_ebs_volume" "sc1" {
  availability_zone = "eu-central-1a"
  size              = 500
  type              = "sc1"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_sc1" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.sc1.id
  instance_id = module.ec2_public.id[0]
}
*/
/****  st1 EBS  ****/
/*
resource "aws_ebs_volume" "st1" {
  availability_zone = "eu-central-1a"
  size              = 500
  type              = "st1"

  tags = local.user_tag
}

resource "aws_volume_attachment" "this_st1" {
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.st1.id
  instance_id = module.ec2_public.id[0]
}
*/

/*
mount a volume
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html

unmount a volume
https://www.digitalocean.com/docs/volumes/how-to/unmount/

check disk speed
https://askubuntu.com/questions/87035/how-to-check-hard-disk-performance

volume name convention
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html#available-ec2-device-names

You've reached the maximum modification rate per volume limit. Wait at least 6 hours between modifications per EBS volume
*/
