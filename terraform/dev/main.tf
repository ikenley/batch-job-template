# ------------------------------------------------------------------------------
# Create the core VPC network infrastructure
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

# Note these should be private subnets in a production environment
data "aws_ssm_parameter" "vpc_id" {
  name = "/${local.namespace}/${local.env}/core/vpc_id"
}

data "aws_ssm_parameter" "vpc_cidr" {
  name = "/${local.namespace}/${local.env}/core/vpc_cidr"
}

data "aws_ssm_parameter" "subnets" {
  name = "/${local.namespace}/${local.env}/core/private_subnets"
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

  job_parameters = { "person" : "HAL" }
  job_command    = ["Ref::person"]

  tags = {}
}
