region                  = "eu-central-1"
awsusername             = "andrea"
public_key              = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCVPI+y9VK/2KhV0kNH1boKE3xTkVIo57fWX1qf8+AR4uu+IIr1sM4LLWcbhTR4WY8okfzv9LoCl/LWg30ODsbLuYX2heamZOuSg5CyFSJj6i2RgS2M2wppKLo13+tEqUm4c4E6dnVk2YHeDs7A5asL1IUGnqvcpey2+ZMTgCEa6nfqxitSl3wWSuMZpNUTXtnQh/3Yp1dMlHjdUuiUCHEKIPyHdz2mF/i6yEf4RPLFWVKpX+o1TpfnoVlFipiobcqiZ0SOOgJsbqWGrykrdnYbvOYtKBpNF3OSTZdBaxRHtH907ykre+9gqTPnQFqq3hncUNQuQvpiv9SlZyuCVmr5 andreabortolossi@Andreas-MBP.lan"
ec2_ami_id              = "ami-0502e817a62226e03" //Ubuntu Server 20.04 LTS (HVM), SSD Volume Type

ec2_t_instance          = true
ec2_i_instance          = false

standard_create         = true
standard_size           = 16
standard_device_name    = "/dev/sdf"

gp2_create              = false
gp2_size                = 16
gp2_device_name         = "/dev/sdg"

io1_create              = false
io1_size                = 32
io1_iops                = 1600
io1_device_name         = "/dev/sdh"

io2_create              = false
io2_size                = 128
io2_iops                = 6400
io2_device_name         = "/dev/sdi"

sc1_create              = false
sc1_size                = 500
sc1_device_name         = "/dev/sdl"

st1_create              = false
st1_size                = 500
st1_device_name         = "/dev/sdm"