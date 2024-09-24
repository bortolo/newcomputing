#!/bin/bash

# get the AWS CLI version
aws --version

# PRODUCER

# CLI v2
aws kinesis put-record --stream-name terraform-kinesis-test --partition-key user1 --data "user signup" --cli-binary-format raw-in-base64-out

# CLI v1
aws kinesis put-record --stream-name test --partition-key user1 --data "user signup"


# CONSUMER 

# describe the stream
aws kinesis describe-stream --stream-name terraform-kinesis-test

# Consume some data
aws kinesis get-shard-iterator --stream-name terraform-kinesis-test --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON

aws kinesis get-records --shard-iterator <>

# to decode the base64 data
https://www.base64decode.org