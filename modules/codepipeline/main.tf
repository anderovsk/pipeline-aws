resource "aws_codepipeline" "codepipeline" {
  name     = var.name
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      namespace        = "SourceVariables"
      region           = "us-east-1"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      run_order        = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github_connection.arn
        FullRepositoryId     = var.repo_name
        BranchName           = var.branch_name
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name      = "approval"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      region    = "us-east-1"
      version   = "1"
      run_order = "1"

      configuration = {
        NotificationArn = aws_sns_topic.topic.arn
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      namespace       = "BuildVariables"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["SourceArtifact"]
      output_artifacts = [
        "BuildArtifact",
      ]
      version   = "1"
      run_order = "1"

      configuration = {
        ProjectName = var.codebuild_name
      }
    }
  }
}

resource "aws_codestarconnections_connection" "github_connection" {
  name          = "${var.name}-gitconn"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "codepipeline-${var.name}"
}

#resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
#  bucket = aws_s3_bucket.codepipeline_bucket.id
#  acl    = "private"
#}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
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
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",
      aws_codepipeline.codepipeline.arn
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github_connection.arn]
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

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy-${var.name}"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}


#SNS
resource "aws_sns_topic" "topic" {
  name = "${var.name}-topic"
}

resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.first_email
}
