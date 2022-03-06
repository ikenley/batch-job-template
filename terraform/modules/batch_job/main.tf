data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.tags, {
    Terraform   = true
    namespace   = var.namespace
    environment = var.environment
  })
  account_id = data.aws_caller_identity.current.account_id
  id         = join("-", [var.namespace, var.environment, var.name])
  # Need to create this locally to avoid circular dep
  codebuild_project_name = local.id
}

# ------------------------------------------------------------------------------
# Compute environment
# ------------------------------------------------------------------------------

resource "aws_batch_compute_environment" "this" {
  compute_environment_name = local.id

  compute_resources {
    max_vcpus = 16

    security_group_ids = [
      module.sg_compute_env.security_group_id
    ]

    subnets = var.subnets

    type = "FARGATE"
  }

  service_role = aws_iam_role.compute_env.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.compute_env]

  tags = local.tags
}

resource "aws_iam_role" "compute_env" {
  name = "${local.id}-batch-service-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "batch.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "compute_env" {
  role       = aws_iam_role.compute_env.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

module "sg_compute_env" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.8.0"

  name   = local.id
  vpc_id = var.vpc_id

  # This should be replaced with a VPC endpoint for ECR
  ingress_cidr_blocks = [var.vpc_cidr]
  ingress_rules       = ["https-443-tcp"]

  egress_rules = ["https-443-tcp"]
}

# ------------------------------------------------------------------------------
# Job Queue
# ------------------------------------------------------------------------------

resource "aws_batch_job_queue" "this" {
  name     = local.id
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.this.arn
  ]
}

# ------------------------------------------------------------------------------
# Job Defnition
# ------------------------------------------------------------------------------

resource "aws_batch_job_definition" "this" {
  name = local.id
  type = "container"

  platform_capabilities = ["FARGATE"]

  parameters = var.job_parameters

  container_properties = jsonencode({
    image            = "${aws_ecr_repository.this[0].repository_url}:latest",
    command          = var.job_command,
    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn,
    volumes          = [],
    environment      = [],
    mountPoints      = [],
    ulimits          = [],
    resourceRequirements = [
      {
        value = var.container_vcpu,
        type  = "VCPU"
      },
      {
        value = var.container_memory,
        type  = "MEMORY"
      }
    ],
    linuxParameters = {
      devices = [],
      tmpfs   = []
    },
    logConfiguration = {
      logDriver     = "awslogs",
      options       = {},
      secretOptions = []
    },
    secrets = [],
    networkConfiguration = {
      assignPublicIp = "ENABLED"
    },
    fargatePlatformConfiguration = {
      platformVersion = "1.4.0"
    }
  })

  tags = local.tags
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "tf_test_batch_exec_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
