variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy into"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}
