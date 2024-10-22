#######################################################################################
# INDEX
#   CODEPIPELINE
#   STAGES CONFIGURATIONS
#       SOURCE (Source)
#       BUILD (Build)
#       DEPLOY (DeployToECS)
#   INFRASTRUTTURA PER PIPELINE
#       S3 for artifacts
#       Github connection
#       ECR repository

#######################################################################################
# CODEPIPELINE 
#######################################################################################

# Definisci il CodePipeline
resource "aws_codepipeline" "my_pipeline" {
  name           = var.pipeline_name
  pipeline_type  = "V2"
  execution_mode = "QUEUED"
  role_arn       = aws_iam_role.codepipeline_role.arn

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

  # Check here for confniguration details
  # https://docs.aws.amazon.com/it_it/codepipeline/latest/userguide/action-reference-ECS.html
  stage {
    name = "Deploy"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.my_cluster.name
        ServiceName = aws_ecs_service.my_service.name
        FileName    = "imagedefinitions.json"
      }

    }
  }

  tags = local.tags

}

#######################################################################################
# STAGES CONFIGURATIONS
#######################################################################################

#######################################################################################
# BUILD STAGE
#######################################################################################

#######################################################################################
# BUILD ACTION
resource "aws_codebuild_project" "my_codebuild" {
  name         = "${var.codebuild_name}-build"
  service_role = aws_iam_role.codebuild_role.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = var.ecr_buildspec_name
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:4.0" #check you runtime at https://docs.aws.amazon.com/it_it/codebuild/latest/userguide/available-runtimes.html
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    /*
  You can manage the variables here or in the buildspec file as you whish
  Check always if the parameter exist and update also the IAM policy to get access
  
     environment_variable {
      name          = "DOCKERHUB_TOKEN"
      value         = "/dockerhub/token"
      type          = "PARAMETER_STORE"
    }

    environment_variable {
      name          = "DOCKERHUB_USER"
      value         = "/dockerhub/user"
      type          = "PARAMETER_STORE"
    }
*/
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "152371567679"
    }
  }

  #TODO: Non si riesce a capire come creare artefatti leggibili su S3
  artifacts {
    type                = "CODEPIPELINE"
    packaging           = "NONE"
    encryption_disabled = true
    namespace_type      = "BUILD_ID"
  }

  build_timeout = 5
  tags          = local.tags
}

#######################################################################################
# INFRASTRUTTURA PER PIPELINE
#######################################################################################

# Bucket S3 per artifact store
# NOTA: si usa questo bucket anche per gli stati tarraform delle infra temporanee (es. staging)
resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "${var.pipeline_name}-artifact-store"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "artifact_bucket" {
  bucket = aws_s3_bucket.artifact_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Endpoint per connettività privata a servizio s3
/*
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [element(module.vpc.public_route_table_ids,0)]
}
*/

# Connessione a github
# NOTA: la connessione deve essere già disponibile per questa region
data "aws_codestarconnections_connection" "example" {
  name = var.github_connection_name
}

# ECR repository
resource "aws_ecr_repository" "my_ecr" {
  name                 = var.application_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
