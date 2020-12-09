#!/bin/sh
echo "Configure terraform variables for RDS"
export TF_VAR_db_username="user"
export TF_VAR_db_password="YourPwdShouldBeLongAndSecure!"
