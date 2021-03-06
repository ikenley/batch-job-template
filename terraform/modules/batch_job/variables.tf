variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "Project name to use as a base for most resources"
}

variable "environment" {
  description = "Environment used for tagging images etc."
}

variable "is_prod" {
  description = ""
  type        = bool
}

variable "name" {}

variable "vpc_id" {}
variable "vpc_cidr" {}
variable "subnets" {
  type = list(string)
}

variable "job_parameters" {
  description = "https://docs.aws.amazon.com/batch/latest/userguide/job_definition_parameters.html"
  type        = map(any)
  default     = {}
}

variable "job_command" {
  description = "Arguments to pass to COMMAND parameter to docker run e.g. [\"Ref::person\"]"
  type        = list(string)
  default     = []
}

variable "container_names" {
  type        = list(string)
  description = "Names of each container. Additional resources are created for each container (e.g. ECR repos)"
  default     = ["main"]
}

variable "container_vcpu" {
  default = "1"
}

variable "container_memory" {
  default = "2048"
}

# CodePipeline
variable "code_pipeline_s3_bucket_name" {}
variable "source_full_repository_id" {}
variable "source_branch_name" {}
variable "codestar_connection_arn" {}
