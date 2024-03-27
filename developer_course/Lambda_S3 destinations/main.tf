locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-lambda-s3destinations"
  }
}
resource "aws_iam_role" "lambda_role" {
name                = "MyTest_Lambda_Function_Role"
assume_role_policy  = file("./resources/lambda_role.json")
tags = local.tags
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy       = file("./resources/lambda_policy.json")
  tags = local.tags

}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}


resource "aws_lambda_function" "terraform_lambda_func" {
filename                       = "./resources/hello-python-v${var.code_version}.zip"
function_name                  = "Lambda_${local.tags.Name}_v${var.code_version}"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index${var.code_version}.lambda_handler"
runtime                        = "python3.8"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]

tags = local.tags
}

# To copy a file on S3
# aws s3 cp ./resources/bucket.jpg s3://my-tf-bucket-developercourse-lambda-s3notification/

resource "aws_s3_bucket" "bucket" {
  bucket = "my-tf-bucket-${local.tags.Name}"

  # these option just to allow an easy way to create and destroy the bucket
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }

  tags = local.tags
}

resource "aws_lambda_permission" "with_s3" {
  statement_id  = "AllowExecutionFrom_s3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.terraform_lambda_func.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.with_s3]
}



resource "aws_sqs_queue" "s3_success" {
  name                      = "s3_success"
  tags = local.tags
}

resource "aws_sqs_queue" "s3_failure" {
  name                      = "s3_failure"
  tags = local.tags
}


resource "aws_lambda_function_event_invoke_config" "destination" {
  function_name = aws_lambda_function.terraform_lambda_func.arn

  destination_config {
    on_failure {
        destination = aws_sqs_queue.s3_failure.arn
    }
    on_success {
        destination = aws_sqs_queue.s3_success.arn
    }
  }
}