awsusername             = "andrea"

AMI_name                = "ASGapp_0_1"

key_pair_name           = "ASGappkey"
ec2_user_data           = <<EOF
                            #!/bin/bash
                            systemctl restart nodejs"
                            EOF

asg_min_size            = 0
asg_max_size            = 4
asg_desired_capacity    = 2
