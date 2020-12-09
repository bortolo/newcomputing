awsusername             = "<your-aws-username>"

AMI_name                = "<ami-name-as-you-set-in-dev-env>"

key_pair_name           = "<key-name-as-you-set-in-cross-env>"
ec2_user_data           = <<EOF
                            #!/bin/bash
                            systemctl restart nodejs"
                            EOF

asg_min_size            = 0
asg_max_size            = 4
asg_desired_capacity    = 2
