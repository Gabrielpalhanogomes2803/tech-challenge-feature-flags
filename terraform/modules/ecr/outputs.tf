output "repository_urls" {
  description = "URLs dos repositórios ECR."
  value       = { for name, repository in aws_ecr_repository.this : name => repository.repository_url }
}

output "repository_arns" {
  description = "ARNs dos repositórios ECR."
  value       = { for name, repository in aws_ecr_repository.this : name => repository.arn }
}
