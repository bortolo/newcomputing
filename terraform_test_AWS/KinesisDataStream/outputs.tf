output KDS_data_id {
    value = aws_kinesis_stream.test_stream.id
    description = "id of KDS"
}

output KDS_data_shards {
    value = aws_kinesis_stream.test_stream.shard_count
    description = "Number of shards"
}