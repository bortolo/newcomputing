#!/bin/bash
export BUCKET_NAME="my-github-pipeline-artifact-store"
aws s3api delete-objects --bucket $BUCKET_NAME --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
terraform destroy -auto-approve