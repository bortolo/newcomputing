#!/bin/sh

echo "Configure environment variable getting the right AMI to run terraform apply"
export TF_VAR_AMI_name="RDSapp_0_1"

echo "Configure environment variable for PROD INFRA to run terraform apply"
export TF_VAR_db_secret_name="db-secret-22"
export TF_VAR_iam_role_name="accessRDS"
export TF_VAR_key_pair_name="RDSappkey"
