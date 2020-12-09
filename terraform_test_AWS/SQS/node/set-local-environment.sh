#!/bin/sh
echo "Configure environment to run node locally"
export TF_VAR_region="eu-central-1"
export TF_VAR_apiVersion="2012-11-05"
export TF_VAR_queueUrl="https://sqs.eu-central-1.amazonaws.com/152371567679/main-SQS-queue"