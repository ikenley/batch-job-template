locals {
  ssm_prefix = "/${var.namespace}/${var.environment}/${var.name}"
}

output "ecs_task_role_name" {
  value = aws_iam_role.ecs_task_role.name
}

resource "aws_ssm_parameter" "ecs_task_role_name" {
  name  = "${local.ssm_prefix}/batch_job/ecs_task_role_name"
  type  = "String"
  value = aws_iam_role.ecs_task_role.name
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

resource "aws_ssm_parameter" "ecs_task_role_arn" {
  name  = "${local.ssm_prefix}/batch_job/ecs_task_role_arn"
  type  = "String"
  value = aws_iam_role.ecs_task_role.arn
}
