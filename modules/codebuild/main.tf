provider "aws" {
  region = "us-east-1"
}

resource "aws_codebuild_project" "anubis_pipeline" {
  name           = "${var.name}-${var.env}"
  build_timeout  = "60"
  queued_timeout = "480"
  source_version = var.source_version
  concurrent_build_limit = "1"
  service_role = var.iam_role

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "NO_CACHE"
    # modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # environment_variable {
    #   name  = "SOME_KEY1"
    #   value = "SOME_VALUE1"
    # }
  }

  source {
    type            = "GITHUB"
    location        = var.github_location
    git_clone_depth = 1
    buildspec = var.buildspec_file
    insecure_ssl = "false"
    git_submodules_config {
        fetch_submodules = false
    }
  }
  

#   tags = {
#     Environment = "Test"
#   }
}

resource "aws_codebuild_webhook" "anubis-pipeline" {
  project_name = aws_codebuild_project.anubis_pipeline.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = var.head_ref
    }
  }
}
