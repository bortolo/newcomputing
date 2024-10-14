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
    key = "index.html"
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
# EC2 
#######################################################################################

# Crea il ruolo IAM per EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.webserver_name}_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

    tags = local.tags
}

# Attacca policy al ruolo di EC2
resource "aws_iam_role_policy" "ec2_policy" {
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ],
        Resource = [
          "*"
        ]
      }
    ]
  })
}

# creazione instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.webserver_name}_instance_profile"
  role = aws_iam_role.ec2_role.name
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-first-webserver"
  cidr = var.network_structure["cidr"][0]

  azs             = var.network_structure["azs"]
  public_subnets  = var.network_structure["public"]
  private_subnets = var.network_structure["private"]

  enable_ipv6        = false
  enable_nat_gateway = false
  single_nat_gateway = false

  public_subnet_tags = local.tags
  private_subnet_tags = local.tags

  vpc_tags = {
    Name        = "vpc-first-webserver"
    Owner       = "andrea.bortolossi"
    Environment = "all"
  }
}

module "security_group_web" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "security-group-web-server"
  description = "Security group for webserver instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp","all-icmp","http-80-tcp"]
  egress_rules        = ["all-all"]

}

resource "aws_key_pair" "this" {
  key_name   = "ec2-key-pair"
  public_key = file("./resources/id_rsa.pub")
}

module "webserver" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                        = "webserver"
  ami                         = "ami-0e6a13e7a5b66ff4d" #Amazon Linux 2
  instance_type               = "t2.micro"
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group_web.security_group_id]
  associate_public_ip_address = true
  key_name                    = "ec2-key-pair"

  user_data_base64            = base64encode(file("./resources/userdata.txt"))
  user_data_replace_on_change = true

  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name


  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = false
      volume_type = "gp2"
      volume_size = 8
      tags = {
        Name = "my-root-block"
      }
    },
  ]

    tags = {
      Application = "MyAngularProject"
    }

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
          "s3:PutObject",
          "s3:ListBucket"
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
      },
      {
        Effect   = "Allow",
        Action   = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ],
        Resource = "*"
      },
            {
        Effect   = "Allow",
        Action   = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetApplicationRevision"
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

  tags = local.tags

}

#######################################################################################
# CODEBUILD - BUILD
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
    tags = local.tags
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
      }
    ]
  })
}

# Progetto CodeBuild - BUILD
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


# Progetto CodeBuild - UNIT TEST
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
# CODEDEPLOY - EC2
#######################################################################################

# Crea il ruolo IAM per codedeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.codedeploy_name}-exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
    }]
  })
    tags = local.tags
}

# Attacca policy al ruolo di codedeploy
resource "aws_iam_role_policy" "codedeploy_policy" {
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DeleteLifecycleHook",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:PutLifecycleHook",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:EnableMetricsCollection",
          "autoscaling:DescribePolicies",
          "autoscaling:DescribeScheduledActions",
          "autoscaling:DescribeNotificationConfigurations",
          "autoscaling:SuspendProcesses",
          "autoscaling:ResumeProcesses",
          "autoscaling:AttachLoadBalancers",
          "autoscaling:AttachLoadBalancerTargetGroups",
          "autoscaling:PutScalingPolicy",
          "autoscaling:PutScheduledUpdateGroupAction",
          "autoscaling:PutNotificationConfiguration",
          "autoscaling:PutWarmPool",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DeleteAutoScalingGroup",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:TerminateInstances",
          "tag:GetResources",
          "sns:Publish",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeInstanceHealth",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        Resource = "*"
      },
      {
        #Needed for Blue Green deployment
        Effect   = "Allow",
        Action   = [
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_codedeploy_app" "foo_app" {
  compute_platform = "Server"
  name             = var.application_name
}

/*resource "aws_codedeploy_deployment_config" "foo" {
  deployment_config_name = "test-deployment-config"

  minimum_healthy_hosts {
    type  = "HOST_COUNT"
    value = 2
  }
}*/

resource "aws_codedeploy_deployment_group" "foo" {
  app_name               = aws_codedeploy_app.foo_app.name
  deployment_group_name  = "TaggedEC2Instances"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  #deployment_config_name = aws_codedeploy_deployment_config.foo.id

  ec2_tag_filter {
    key   = "Application"
    type  = "KEY_AND_VALUE"
    value = "MyAngularProject"
  }

}