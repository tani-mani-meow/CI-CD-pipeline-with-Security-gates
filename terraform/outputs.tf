output "app_url" {
  description = "URL to access the application (ALB DNS)"
  value       = "http://${module.alb.alb_dns_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL (for docker push)"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "ecs_task_definition_family" {
  description = "ECS task definition family"
  value       = module.ecs.task_definition_family
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for container logs"
  value       = module.ecs.log_group_name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions (use in workflow)"
  value       = module.iam.github_actions_role_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
