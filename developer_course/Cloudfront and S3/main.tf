locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-cloudfront-s3"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "my-bucket-${local.tags.Name}"
  tags = local.tags
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}


# OTHER ORIGIN

resource "aws_s3_bucket" "other_origin" {
  bucket = "my-bucket-other-origin-${local.tags.Name}"
  tags = local.tags
}

resource "aws_s3_bucket_versioning" "other_origin" {
  bucket = aws_s3_bucket.other_origin.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "other_origin" {
  bucket = aws_s3_bucket.other_origin.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

resource "aws_s3_bucket_public_access_block" "other_origin" {
  bucket = aws_s3_bucket.other_origin.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_policy" "other_origin" {
  bucket = aws_s3_bucket.other_origin.id
  policy = file("./resources/other_origin_policy.json")
}

resource "aws_s3_bucket_cors_configuration" "other_origin" {
  bucket = aws_s3_bucket.other_origin.id
  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://my-bucket-developercourse-cloudfront-s3.s3.eu-central-1.amazonaws.com/index.html?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEGgaDGV1LWNlbnRyYWwtMSJFMEMCH3aCyVU0UcR3894iHgPIaGYRMazBVDVc4mY4FexXT1QCICZP8PCB6CkmPEStUwA7td4y6D9%2FOsgd0ACCeMoYEB1gKv0CCBEQBBoMMTUyMzcxNTY3Njc5IgzUwIGlR%2BnfIv6nlasq2gIK2%2FpoX32pokeKYHJwfmyzG7qngTgZYDbP5eRY1KgUvGRf2cfc7mGbrsJi3BEqg5Go1cv7Tujw4QkFtj9ctSl4Nw%2BFtwy9CDFJyYTuQnS%2FQHR2iyRn%2FQ2ZDo%2Fy8udmkei%2FEQy0oJifWZP3PoAf%2F3DD0lQjXYvMS99NKAEfG%2FQPj3BrDrTZHe70G965JHwhy6zpehWyv5ezG%2BoaD9VckQdoLfj9dpZWUvM7X4S2zYR0wKISw8WZDZby58fauwz%2F69Q4xtL5J8e%2FvBowCxw3oNpm3SE%2BBI0ibQakVDzc2Z45gXs%2BAHZS%2BIKsWxYSJOm%2FuW6FjfEYC6ylbVFsGtF9JQbYTvAMM5zd5qWFsHK3hE2BoTki3H9dx6pN5X6w7javmQQ57%2BruEynnvJwALwFiI4Y7nhxNNz8dUs0nXZqG4UyCGBKEXft5zh5nXgp5259vVw6taHYo2kDl7MxDMLn1xLMGOrUCNx6u7eOf%2BOvd620BuI%2BUJ1sNR8MEWSm4PSB6A9%2F8zA6IyMhUX5s636qrybl056SsFHHF7eunxstyZmsHM8U7GyBvjEyG4IaLBaUfsbYh%2B%2FRUnMXgzynf6eCv8SEK2%2B3hbJw%2BSGMk9oAKVGOdz%2B1kYIt9xZEm42MM%2Fd4KOeB3%2BSNVc2JEZI3gVVOjo7eHqnSpP6c39ExP%2B%2F880syz2orT3vclRIi4H%2FiPJbjwuzszdT9LW%2FsvBAdGqvtZYKzeoR09ZzRzJIZSnxTnksl4y0uCLd4xrrpHOeDATD2PzUxrXWunTFpgPQJ9H2vzlKIdKMP0lDgZ8P%2F8Y6FTneWhy0WB9AgFFHnUyXvCgR0dyMvs9mTVcJl%2Fgav6xbuG38VC7wW7x6f4j%2F61OYQYZr2SPWN44uzg274k&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20240618T121037Z&X-Amz-SignedHeaders=host&X-Amz-Expires=300&X-Amz-Credential=ASIASG6QNTQ76HIH5GNW%2F20240618%2Feu-central-1%2Fs3%2Faws4_request&X-Amz-Signature=5fd8a81e5566dc59e5a706722821aff54ef0eb6a4214c3a9bf480413e6cf0393"]
    expose_headers  = []
    max_age_seconds = 3000
    }
}