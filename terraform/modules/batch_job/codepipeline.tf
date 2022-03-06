#------------------------------------------------------------------------------
# CodePipeline and related resources
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ECR
#------------------------------------------------------------------------------

resource "aws_ecr_repository" "this" {
  count = length(var.container_names)

  name                 = "${local.id}-${var.container_names[count.index]}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

#------------------------------------------------------------------------------
# CodePipeline
#------------------------------------------------------------------------------

resource "aws_codepipeline" "this" {
  name     = local.id
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.code_pipeline_s3_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        "BranchName" : var.source_branch_name
        "ConnectionArn" : var.codestar_connection_arn
        "FullRepositoryId" : var.source_full_repository_id
        "OutputArtifactFormat" : "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"

      configuration = {
        ProjectName = local.codebuild_project_name
      }
    }
  }

  # stage {
  #   name = "Deploy"

  #   action {
  #     name            = "Deploy"
  #     category        = "Deploy"
  #     owner           = "AWS"
  #     provider        = "ECS"
  #     input_artifacts = ["BuildArtifact"]
  #     version         = "1"

  #     configuration = {
  #       "ClusterName" : local.ecs_cluster_name
  #       "ServiceName" : aws_ecs_service.this.name
  #     }
  #   }
  # }
}

resource "aws_iam_role" "codepipeline" {
  name = "${var.name}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codepipeline" {
  name        = "${local.id}-codepipeline-policy"
  description = "Codepipeline policy for ${local.id}"

  policy = templatefile("${path.module}/codepipeline_policy.tpl", {
    code_pipeline_s3_bucket_name = var.code_pipeline_s3_bucket_name
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.id
  policy_arn = aws_iam_policy.codepipeline.arn
}

#------------------------------------------------------------------------------
# CodeBuild
#------------------------------------------------------------------------------

resource "aws_codebuild_project" "this" {
  name        = local.codebuild_project_name
  description = "CodeBuild project for ${local.id}"

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
    name = aws_codepipeline.this.name
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "TF_ENV"
      value = var.environment
    }

    environment_variable {
      name  = "BRANCH_NAME"
      value = var.source_branch_name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

    environment_variable {
      name  = "JOB_DEFINITION"
      value = aws_batch_job_definition.this.name
    }

    dynamic "environment_variable" {
      for_each = aws_ecr_repository.this.*
      content {
        name  = "${upper(replace(environment_variable.value.name, "${local.id}-", ""))}_IMAGE_REPO_NAME"
        value = environment_variable.value.name
      }
    }

  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.tags
}

resource "aws_iam_role" "codebuild" {
  name = "${var.name}-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild" {
  name        = "${local.id}-codebuild-policy"
  description = "Codebuild policy for ${local.id}"

  policy = templatefile("${path.module}/codebuild_policy.tpl", {
    account_id                   = local.account_id
    code_pipeline_s3_bucket_name = var.code_pipeline_s3_bucket_name
    ecr_arns                     = jsonencode(aws_ecr_repository.this.*.arn)
    codebuild_project_name       = local.codebuild_project_name
    name                         = var.name
    job_definition               = aws_batch_job_definition.this.name
    batch_job_role_arn           = aws_iam_role.ecs_task_execution_role.arn
  })
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.id
  policy_arn = aws_iam_policy.codebuild.arn
}
