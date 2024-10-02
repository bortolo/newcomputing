aws_region      = "eu-central-1"
lambda_name     = "lambda_hello_world"
bucket_name     = "my-codepipeline-bucket-developercourse-final-experiment"
codebuild_name  = "my_codebuild_project"
#zip_file_name   = ""
github_secret   = "/developer-course/lambda-codepipeline/githubtoken" #must be already defined in SSM parameter store
github_url      = "https://github.com/bortolo/lambda_codepipeline_AWS.git"