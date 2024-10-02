locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "developercourse-SSM-lambda-codepipeline"
  }
}

#######################################################################################
# LAMBDA
#######################################################################################

# Ruolo IAM per Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Policy IAM per Lambda
resource "aws_iam_role_policy" "lambda_exec_policy" {
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Crea la Lambda function (assumi che l'handler e il ruolo siano già definiti)
resource "aws_lambda_function" "my_lambda" {
  filename         = "build_output.zip"
  function_name    = "my_lambda_function"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("build_output.zip")
}

#######################################################################################
# CODEBUILD
#######################################################################################

# Crea il ruolo IAM per codebuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

# Attacca policy al ruolo di codebuild
resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = [
          "*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "lambda:UpdateFunctionCode"
        ],
        Resource = "${aws_lambda_function.my_lambda.arn}"
      },
      {
        Effect   = "Allow",
        Action   = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect  = "Allow",
        Action  = [
           "secretsmanager:GetSecretValue"
        ],
        Resource = "*"
      }
    ]
  })
}

# Progetto CodeBuild
resource "aws_codebuild_project" "my_codebuild" {
  name          = "my_codebuild_project"
  service_role  = aws_iam_role.codebuild_role.arn

  source {
    type      = "GITHUB"
    location  = "https://github.com/bortolo/lambda_codepipeline_AWS.git"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    environment_variable {
      name  = "ENV_VAR"
      value = "my_value"
    }
  }

  artifacts {
    type = "S3"
    location = "my-codepipeline-bucket-developercourse-experiments-3"
    packaging = "ZIP"

  }

  build_timeout = 5
}

#######################################################################################
# CODEPIPELINE 
#######################################################################################

# Crea il ruolo IAM per CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

# Attacca policy al ruolo di CodePipeline
resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "lambda:UpdateFunctionCode"
        ],
        Resource = "${aws_lambda_function.my_lambda.arn}"
      },
      {
        Effect   = "Allow",
        Action   = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ],
        Resource = "*"
      }
    ]
  })
}

# Github tocken
data "aws_ssm_parameter" "github_token" {
  name = "/developer-course/lambda-codepipeline/githubtoken" # Il nome del parametro SSM che vuoi ottenere
  # Se il parametro è di tipo "SecureString" (cifrato), aggiungi questo
  with_decryption = true
}

# Bucket S3 per la pipeline (memorizza artefatti build)
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "my-codepipeline-bucket-developercourse-experiments-3"
  tags = local.tags
}

/*
# Definisci il CodePipeline
resource "aws_codepipeline" "my_pipeline" {
  name     = "my_pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  # Fase di origine (Source) da GitHub
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "bortolo"
        Repo       = "git@github.com:bortolo/lambda_codepipeline_AWS.git"
        Branch     = "main" # o il branch che desideri monitorare
        OAuthToken = data.aws_ssm_parameter.github_token.value
      }
    }
  }

  # Fase di compilazione (Build)
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.my_codebuild.name
      }
    }
  }

  # Fase di distribuzione (Deploy)
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "Lambda"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        FunctionName = aws_lambda_function.my_lambda.function_name
        S3Bucket     = aws_s3_bucket.codepipeline_bucket.bucket
        S3ObjectKey  = "build_output.zip"
      }
    }
  }
}

*/