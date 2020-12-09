#!/bin/sh
echo "Configure terraform variables for EC2andRDS"
export TF_VAR_db_username="user"
export TF_VAR_db_password="YourPwdShouldBeLongAndSecure!"
export TF_VAR_db_private_dns="database.example.com"
