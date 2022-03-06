# ------------------------------------------------------------------------------
# Create AWS Batch Job for a given environment
# ------------------------------------------------------------------------------

locals {
  namespace = "ik"
  env       = "dev"
  is_prod   = false
}

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "batch-job-template/terraform.tfstate"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform-dev"
}

#
# Batch job - example
#

data "aws_ssm_parameter" "vpc_id" {
  name = "/${local.namespace}/${local.env}/core/vpc_id"
}

data "aws_ssm_parameter" "vpc_cidr" {
  name = "/${local.namespace}/${local.env}/core/vpc_cidr"
}

data "aws_ssm_parameter" "subnets" {
  name = "/${local.namespace}/${local.env}/core/private_subnets"
}

data "aws_ssm_parameter" "code_pipeline_s3_bucket_name" {
  name = "/${local.namespace}/${local.env}/core/code_pipeline_s3_bucket_name"
}

module "batch_job_example" {
  source = "../modules/batch_job"

  namespace   = local.namespace
  environment = local.env
  is_prod     = local.is_prod

  name     = "batch-example"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  vpc_cidr = data.aws_ssm_parameter.vpc_cidr.value
  subnets  = split(",", data.aws_ssm_parameter.subnets.value)

  job_parameters = { person = "HAL" }
  job_command    = ["Ref::person"]

  code_pipeline_s3_bucket_name = data.aws_ssm_parameter.code_pipeline_s3_bucket_name.value
  source_full_repository_id    = "ikenley/batch-job-template"
  source_branch_name           = "main"
  codestar_connection_arn      = "arn:aws:codestar-connections:us-east-1:924586450630:connection/73e9e607-3dc4-4a4d-9f81-a82c0030de6d"

  tags = {}
}
