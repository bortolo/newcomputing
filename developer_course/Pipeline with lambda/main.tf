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
  name = "${var.lambda_name}-exec_role"

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
      },
      {
        "Action": [
          "dynamodb:Scan",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Describe*",
          "dynamodb:List*",
          "dynamodb:GetResourcePolicy",
          "dynamodb:Query",
          "dynamodb:PartiQLSelect",
          "dynamodb:DeleteItem",
          "dynamodb:DeleteTable",
          "dynamodb:*"
        ],
        "Resource": "arn:aws:dynamodb:*:152371567679:table/*",
        "Effect": "Allow"
      }
    ]
  })
}

# Crea la Lambda function (assumi che l'handler e il ruolo siano già definiti)
# Per la prima creazione un pacchetto fittizio bulid_output.zip deve essere definito 
# Non cambiare il nome, se occorre farlo ricordarsi di aggiornare anche buildspec.yml
resource "aws_lambda_function" "my_lambda" {
  filename         = "./resources/build_output.zip" #dummy code to build the very first lambda
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.8"
  #source_code_hash = filebase64sha256("./resources/build_output.zip")

  environment {
    variables = {ListOfUsers_table = aws_dynamodb_table.ListOfUsers.name}
}
}


resource "aws_lambda_alias" "prod_lambda_alias" {
  name             = "prod"
  description      = "Alias for production"
  function_name    = aws_lambda_function.my_lambda.arn
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "test_lambda_alias" {
  name             = var.test_alias
  description      = "Alias for test"
  function_name    = aws_lambda_function.my_lambda.arn
  function_version = "$LATEST"
}

#######################################################################################
# DYNAMO DB
#######################################################################################

resource "aws_dynamodb_table" "ListOfUsers" {
  name           = "ListOfUsers"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "employeeid"

  attribute {
    name = "employeeid"
    type = "S"
  }

  tags = local.tags
}

#######################################################################################
# CODEBUILD
#######################################################################################

# Crea il ruolo IAM per codebuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.codebuild_name}-exec_role"

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
          "lambda:UpdateFunctionCode",
          "lambda:InvokeFunction",
          "lambda:PublishVersion",
          "lambda:ListVersionsByFunction",
          "lambda:UpdateAlias"
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
  name          = "${var.codebuild_name}-update-code"
  service_role  = aws_iam_role.codebuild_role.arn

  source {
    type      = "GITHUB"
    location  = var.github_url
    buildspec = file("./resources/buildspec-update.yml")
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    environment_variable {
      name  = "LAMBDA_NAME"
      value = var.lambda_name
    }
    environment_variable {
      name  = "BUCKET_NAME"
      value = var.bucket_name
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  build_timeout = 5
}

#tra codebuild e pipeline non funziona ancora bene il webhook autoomatico!!!

# Progetto CodeBuild
resource "aws_codebuild_project" "deploy_alias" {
  name          = "${var.codebuild_name}-deploy-alias"
  service_role  = aws_iam_role.codebuild_role.arn

  source {
    type      = "NO_SOURCE"
    buildspec = file("./resources/buildspec-deploy.yml")
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    environment_variable {
      name  = "LAMBDA_NAME"
      value = var.lambda_name
    }
    environment_variable {
      name  = "ALIAS_NAME"
      value = var.test_alias
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  build_timeout = 5
}

/*
  Codebuild only allows a single credential per given server type in a given region. 
  Therefore, when you define aws_codebuild_source_credential, aws_codebuild_project 
  resource defined in the same module will use it.
*/
resource "aws_codebuild_source_credential" "example" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = data.aws_ssm_parameter.github_token.value
}

resource "aws_codebuild_webhook" "example" {
  project_name = aws_codebuild_project.my_codebuild.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }
  }
}

# Github token
data "aws_ssm_parameter" "github_token" {
  name = var.github_secret # Il nome del parametro SSM che vuoi ottenere
  # Se il parametro è di tipo "SecureString" (cifrato), aggiungi questo
  with_decryption = true
}

# Bucket S3 per la pipeline (memorizza artefatti build)
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.bucket_name
  tags = local.tags
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
        Repo       = "lambda_codepipeline_AWS.git"
        Branch     = "main" # o il branch che desideri monitorare
        OAuthToken = data.aws_ssm_parameter.github_token.value
      }
    }
  }

  # Fase di compilazione (Build)
  stage {
    name = "BuildTest"

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

stage {
    name = "ApprovalToVersion"

    action {
      name             = "ApprovalAction"
      category         = "Approval"
      owner            = "AWS"
      provider         = "Manual"
      version          = "1"
      /*configuration = {
        NotificationARNs = ["arn:aws:sns:eu-central-1:123456789012:your-sns-topic"]  # Sostituisci con il tuo ARN SNS
        CustomData       = "Please approve the deployment of the new Lambda version."
        Stage             = "ApprovalStage"
      }*/
    }
  }

    # Fase di update version
  stage {
    name = "BuildVersion"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      #output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.deploy_alias.name
      }
    }
  }

/*
    stage {
    name = "Build prod version"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.my_codebuild_prod.name
      }
    }
  }
  */

}
