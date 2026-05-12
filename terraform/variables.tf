variable "project_name" {
  description = "Name of the project — used for resource naming"
  type        = string
  default     = "cicd-pipeline"
}

variable "environment" {
  description = "Deployment environment (staging, production)"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "container_port" {
  description = "Port the application listens on inside the container"
  type        = number
  default     = 3000
}

variable "container_cpu" {
  description = "CPU units for the Fargate task (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory in MB for the Fargate task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
  default     = "/health"
}

variable "github_repository" {
  description = "GitHub repository in the format 'owner/repo'"
  type        = string
}

variable "github_oidc_thumbprint" {
  description = "GitHub OIDC thumbprint (rarely changes)"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "container_image_tag" {
  description = "Docker image tag to deploy (updated by CI/CD)"
  type        = string
  default     = "latest"
}
