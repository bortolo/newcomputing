#######################################################################################
# INDEX
#   CODEPIPELINE
#   STAGES CONFIGURATIONS
#       BUILD
#       STAGING
#       DEPLOY
#   INFRASTRUTTURA PER PIPELINE

#######################################################################################
# CODEPIPELINE 
#######################################################################################

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
/*
  stage {
    name = "Build"

    action {
      name             = "UnitTest"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.my_codebuild_unit_test.name
      }

      run_order = 1
    }

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

      run_order = 2
    }
  }
*/
  # Fase di Stage
    stage {
    name = "Staging"

    action {
      name             = "BuildStack"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.my_codebuild_staging_apply.name
      }
      run_order = 1
    }

    action {
      name             = "DestroyStack"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.my_codebuild_staging_destroy.name
      }
      run_order = 2
    }

  }
/*
  # Fase di deploy
  stage {
    name = "Deploy"

    action {
      name             = "DeployToEC2"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeploy"
      version          = "1"
      input_artifacts  = ["build_output"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.foo_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.foo.deployment_group_name
      }
    }
  }
*/
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
  name                   = "${var.codebuild_name}-build"
  service_role           = aws_iam_role.codebuild_role.arn
  #concurrent_build_limit = 1

  source {
    type      = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0" #check you runtime at https://docs.aws.amazon.com/it_it/codebuild/latest/userguide/available-runtimes.html
    type                        = "LINUX_CONTAINER"
  }

  # Non si riesce a capire come creare artefatti leggibili su S3
  # L'alternativa è copiarli con comandi da terminali dentro la build e gestire separatamente la gestione degli artifacts
  artifacts {
    type = "CODEPIPELINE"
    packaging = "NONE"
    encryption_disabled = true
    namespace_type = "BUILD_ID"
  }

  build_timeout = 5
  tags = local.tags
}

#######################################################################################
# UNIT TEST ACTION
resource "aws_codebuild_project" "my_codebuild_unit_test" {
  name                   = "${var.codebuild_name}-unit-test"
  service_role           = aws_iam_role.codebuild_role.arn
  #concurrent_build_limit = 1

  source {
    type      = "CODEPIPELINE"
    buildspec = var.unit_test_buildspec_name
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0" #check you runtime at https://docs.aws.amazon.com/it_it/codebuild/latest/userguide/available-runtimes.html
    type                        = "LINUX_CONTAINER"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  build_timeout = 5
  tags = local.tags
}

#######################################################################################
# STAGING STAGE
#######################################################################################

#######################################################################################
# STAGING APPLY
resource "aws_codebuild_project" "my_codebuild_staging_apply" {
  name                   = "${var.codebuild_name}-staging-apply"
  service_role           = aws_iam_role.codebuild_role.arn
  #concurrent_build_limit = 1
  source {
    type      = "CODEPIPELINE"
    buildspec = var.apply_staging_buildspec_name
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0" #check you runtime at https://docs.aws.amazon.com/it_it/codebuild/latest/userguide/available-runtimes.html
    type                        = "LINUX_CONTAINER"
    environment_variable {
      # usiamo lo stesso s3 bucket che usiamo per artifact per comodità
      name  = "s3-arn-tf-state"
      value = aws_s3_bucket.artifact_bucket.bucket # verificare che serve arn o altro riferimento
    }
    environment_variable {
      name  = "vpc_id"
      value = module.vpc.vpc_id
    }
    environment_variable {
      name  = "ami_id"
      value = "ami-003475c38636343f5"
    }
    environment_variable {
      name  = "availability_zone"
      value = element(module.vpc.azs, 0)
    }
    environment_variable {
      name  = "subnet_id"
      value = element(module.vpc.public_subnets, 0) #stessa subnet pubblica della prod, non ok
    }
    environment_variable {
      name  = "ec2_key_pair"
      value = "ec2-key-pair"
    }
    environment_variable {
      name  = "iam_instance_profile"
      value = aws_iam_instance_profile.ec2_instance_profile.name
    }
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  build_timeout = 5
  tags = local.tags
}

#######################################################################################
# STAGING DESTROY
resource "aws_codebuild_project" "my_codebuild_staging_destroy" {
  name                   = "${var.codebuild_name}-staging-destroy"
  service_role           = aws_iam_role.codebuild_role.arn
  #concurrent_build_limit = 1
  source {
    type      = "CODEPIPELINE"
    buildspec = var.destroy_staging_buildspec_name
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0" #check you runtime at https://docs.aws.amazon.com/it_it/codebuild/latest/userguide/available-runtimes.html
    type                        = "LINUX_CONTAINER"
    environment_variable {
      # usiamo lo stesso s3 bucket che usiamo per artifact per comodità
      name  = "s3-arn-tf-state"
      value = aws_s3_bucket.artifact_bucket.bucket # verificare che serve arn o altro riferimento
    }
    environment_variable {
      name  = "vpc_id"
      value = module.vpc.vpc_id
    }
    environment_variable {
      name  = "ami_id"
      value = "ami-003475c38636343f5"
    }
    environment_variable {
      name  = "availability_zone"
      value = element(module.vpc.azs, 0)
    }
    environment_variable {
      name  = "subnet_id"
      value = element(module.vpc.public_subnets, 0) #stessa subnet pubblica della prod, non ok
    }
    environment_variable {
      name  = "ec2_key_pair"
      value = "ec2-key-pair"
    }
    environment_variable {
      name  = "iam_instance_profile"
      value = aws_iam_instance_profile.ec2_instance_profile.name
    }
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  build_timeout = 5
  tags = local.tags
}
#######################################################################################
# DEPLOY STAGE
#######################################################################################
/*
# Configurazione di codedeploy
resource "aws_codedeploy_app" "foo_app" {
  compute_platform = "Server"
  name             = var.application_name
}

resource "aws_codedeploy_deployment_group" "foo" {
  app_name               = aws_codedeploy_app.foo_app.name
  deployment_group_name  = "MyAutoscalingGroup"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  autoscaling_groups     = [aws_autoscaling_group.webserver_asg.name]
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  #aws_codedeploy_deployment_config.foo.id

auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.front_end.arn]
      }
      target_group {
        name = aws_lb_target_group.my_target_group_for_alb.name
      }
    }
  }

}
*/
#######################################################################################
# INFRASTRUTTURA PER PIPELINE
#######################################################################################

# Bucket S3 per artifact store
# NOTA: si usa questo bucket anche per gli stati tarrefoarmo delle infra temporanee (es. staging)
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

# Endpoint per connettività privata a servizio s3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [element(module.vpc.public_route_table_ids,0)]
}

# Connessione a github
# NOTA: la connessione deve essere già disponibile per questa region
data "aws_codestarconnections_connection" "example" {
  name = var.github_connection_name
}

# Endpoint per onnettività privata a servizio codedeploy-commands-secure
resource "aws_vpc_endpoint" "codedeploy_1" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.codedeploy-commands-secure"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [element(module.vpc.public_subnets, 0),element(module.vpc.public_subnets, 1)]
  security_group_ids = [aws_security_group.allow_codedeploy.id]
  private_dns_enabled = true
  tags = local.tags
}

# Endpoint per onnettività privata a servizio codedeploy
resource "aws_vpc_endpoint" "codedeploy_2" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.codedeploy"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [element(module.vpc.public_subnets, 0),element(module.vpc.public_subnets, 1)]
  security_group_ids = [aws_security_group.allow_codedeploy.id]
  private_dns_enabled = true
  tags = local.tags
}

# Security group da associare a enpoint interface per codedeploy
resource "aws_security_group" "allow_codedeploy" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.network_structure.cidr
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}


