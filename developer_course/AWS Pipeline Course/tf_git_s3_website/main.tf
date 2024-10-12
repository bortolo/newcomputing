locals {
  tags = {
    Owner       = "andrea.bortolossi"
    Name        = "AWS-course-codepipeline"
  }
}

#######################################################################################
# PROD BUCKET website
#######################################################################################

# Bucket S3 per il website
resource "aws_s3_bucket" "prod_bucket" {
  bucket = var.bucket_prod
  tags = local.tags
}

resource "aws_s3_bucket_website_configuration" "prod_bucket" {
  bucket = aws_s3_bucket.prod_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_versioning" "prod_bucket" {
  bucket = aws_s3_bucket.prod_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "prod_bucket" {
  bucket = aws_s3_bucket.prod_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Configura le policy del bucket per permettere l'accesso pubblico
resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.prod_bucket.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.prod_bucket.arn}/*"
      }
    ]
  })
}

#######################################################################################
# CODEPIPELINE 
#######################################################################################

# Bucket S3 per artifact store
resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "${var.pipeline_name}-artifact-store"
  tags = local.tags
}

resource "aws_s3_bucket_versioning" "artifact_bucket" {
  bucket = aws_s3_bucket.artifact_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Crea il ruolo IAM per CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.pipeline_name}_role"

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

    tags = local.tags
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
          "codestar-connections:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Connessione a github
# La connessione deve essere già disponibile per questa region
data "aws_codestarconnections_connection" "example" {
  name = var.github_connection_name
}

# Definisci il CodePipeline
resource "aws_codepipeline" "my_pipeline" {
  name     = var.pipeline_name
  pipeline_type = "V2"
  execution_mode = "QUEUED"
  role_arn = aws_iam_role.codepipeline_role.arn
  

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }


  # Fase di origine (Source) da GitHub
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = data.aws_codestarconnections_connection.example.arn
        FullRepositoryId     = var.github_repo
        BranchName           = "master"
        DetectChanges        = true
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  # Fase di deploy
  stage {
    name = "Deploy"

    action {
      name             = "DeployAction"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      input_artifacts  = ["source_output"]

      configuration = {
        BucketName = aws_s3_bucket.prod_bucket.bucket
        Extract    = "true"
      }
    }
  }

  tags = local.tags

}
