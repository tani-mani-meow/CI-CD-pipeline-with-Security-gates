variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in 'owner/repo' format"
  type        = string
}

variable "github_oidc_thumbprint" {
  description = "GitHub OIDC thumbprint"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository (for scoped push permissions)"
  type        = string
}
