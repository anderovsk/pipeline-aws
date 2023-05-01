provider "aws" {
  region = "us-east-1"
}

resource "aws_codebuild_project" "codebuild" {
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

resource "aws_codebuild_webhook" "codebuild" {
  project_name = aws_codebuild_project.codebuild.name
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

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "${var.name}-role-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "sns:Publish",
    ]

    resources = [
      aws_codebuild_project.codebuild.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "sns:Publish"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "codebuild_policy-${var.name}"
  role   = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}
