region                  = "eu-central-1"
awsusername             = "andrea"
key_pair_name           = "cloudwatch-key"
public_key              = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+5yCUcpYQbw9XHLiuZn3F8IeEqP4e+KFnOCRxM1t8b+VybSNmoZES+XFXrMBViFS1Bf8iUMTUg16bkJRqDMwDTRgMZpu33dPpaQvX2OT7GVvfj/oCyE7zImB5+wPOxP0YLfHJ8w4mU155OpksG+j8cbSwrLeFAdqs/Sw1Lk/1QnkoRCGG3vIVJ1ARrAQO6+lsQjjq9Du2KD0JsAgwke2VbYKBZMTWNd7XOc05WRuSPB4PNcazYuRP+Ie3Puo9Oz6zsjIG5Sl3LVAHx5MOMLIKtokvfrAQn7CBA8M7nKcbygZAgVAB2y6XkZWt4cIRII4zyJc0/ChMux3DZDfa9XVqPDtOlzBkm6Db1H1NzC7myqke8aBZYBnfgwnQpPGuyTBd7Ms4IcBQTH6n6tFqs9Z4qGChJtVgYUByJtE6VkWOcla3eSfklPLqP62Hm3swJUE28J9QTabKiexMWN6uHMqo5L84h6U87AtOQNqCz1+pSdLgOC/75gEoGUCeQdbM10M= andreabortolossi@MacBook-Pro-di-Andrea.local"
ec2_name                = "fe_server-dev"
ec2_number_of_instances = 3
ec2_ami_id              = "ami-0bd39c806c2335b95"
ec2_instance_type       = "t2.micro"
ec2_public_ip           = true
ec2_detailed_monitoring = true
iam_cloudwatch_logs     = "CloudWatchLogs"