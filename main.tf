# terraform {
#   backend "s3" {
#     bucket = "anderovsk-terraform"
#     key    = "codebuild-tripee.tfstate"
#     region = "us-east-1"
#   }

#   required_providers {
#     aws = {
#       version = "~> 3.50.0"
#     }
#   }
# }

module "codebuild" {
  source                  = "./modules/codebuild"
  name                    = "anubis-pipeline"
  env                     = terraform.workspace
  github_location         = "https://github.com/anderovsk/serverlesss-pipeline-codebuild.git"
  source_version          = lookup(var.branch_name, terraform.workspace)
  head_ref                = lookup(var.branch_name, terraform.workspace) 
  iam_role                = "arn:aws:iam::755424459357:role/service-role/codebuild-anderovsk"
  buildspec_file          = "buildspec.yml"
}

module "codepipeline" {
  source                  = "./modules/codepipeline"
  count = terraform.workspace == "prod" ? 1 : 0
  name                    = "anubis-pipeline-${terraform.workspace}"
  repo_name               = "anderovsk/serverlesss-pipeline-codebuild"
  branch_name             = lookup(var.branch_name, terraform.workspace)
  codebuild_name          = "anubis-pipeline-${terraform.workspace}"
  first_email             = "anderon.delima@gmail.com"
}
