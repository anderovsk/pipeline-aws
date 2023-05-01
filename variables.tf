variable "branch_name" {
  default = {
    dev  = "development"
    stg  =  "staging"
    prod = "production"
  }
}

variable "name" {
  default = "anubis-pipeline"
}

variable "first_email" {
  default = "anderon.delima@gmail.com"
}

variable "repo_name" {
  default = "anderovsk/serverlesss-pipeline-codebuild"
}

variable "git_location" {
  default = ""
}
