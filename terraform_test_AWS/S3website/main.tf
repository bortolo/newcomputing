provider "aws" {
  region = "eu-central-1"
}

locals {
  user_tag = {
    Owner = var.awsusername
    Test  = "S3website"
  }
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = var.domain_name
  acl    = "public-read"
  policy = data.aws_iam_policy_document.website_policy.json
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
  force_destroy = true

  tags = local.user_tag
}

resource "aws_s3_bucket" "website_bucket_www" {
  bucket = "www.${var.domain_name}"
  acl    = "public-read"
  policy = data.aws_iam_policy_document.website_policy_2.json
  website {
    redirect_all_requests_to = "http://${var.domain_name}"
  }
  force_destroy = true

  tags = local.user_tag
}

data "aws_iam_policy_document" "website_policy" {
  statement {
    actions = [
      "s3:GetObject",
    ]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    resources = [
      "arn:aws:s3:::${var.domain_name}/*",
    ]
  }
}

data "aws_iam_policy_document" "website_policy_2" {
  statement {
    actions = [
      "s3:GetObject",
    ]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    resources = [
      "arn:aws:s3:::www.${var.domain_name}/*",
    ]
  }
}


resource "aws_route53_zone" "primary" {
  name = var.domain_name

  tags = local.user_tag
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_s3_bucket.website_bucket.website_domain
    zone_id                = aws_s3_bucket.website_bucket.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www2" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www."
  type    = "A"
  alias {
    name                   = aws_s3_bucket.website_bucket_www.website_domain
    zone_id                = aws_s3_bucket.website_bucket_www.hosted_zone_id
    evaluate_target_health = true
  }
}
