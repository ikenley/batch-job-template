# ------------------------------------------------------------------------------
# Example batch job. Extends the core batch job with job-specific resources
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  id         = join("-", [var.namespace, var.environment, var.name])
  id_path    = join("/", [var.namespace, var.environment, var.name])
  account_id = data.aws_caller_identity.current.account_id
}

module "batch_job" {
  source = "../batch_job"

  namespace   = var.namespace
  environment = var.environment
  is_prod     = var.is_prod

  name     = var.name
  vpc_id   = var.vpc_id
  vpc_cidr = var.vpc_cidr
  subnets  = var.subnets

  job_parameters = var.job_parameters
  job_command    = var.job_command

  code_pipeline_s3_bucket_name = var.code_pipeline_s3_bucket_name
  source_full_repository_id    = var.source_full_repository_id
  source_branch_name           = var.source_branch_name
  codestar_connection_arn      = var.codestar_connection_arn

  tags = var.tags
}

# Sample IAM policy for Task Role
resource "aws_iam_policy" "ecs_task_role" {
  name        = "${local.id}-task-role-policy"
  description = "Task Role policy for ${local.id}"

  policy = templatefile("${path.module}/ecs_task_policy.tpl", {
    account_id           = local.account_id
    s3_bucket_name       = "example-bucket-name"
    ssm_param_path       = local.id_path
    secrets_manager_path = local.id_path
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role       = module.batch_job.ecs_task_role_name
  policy_arn = aws_iam_policy.ecs_task_role.arn
}
