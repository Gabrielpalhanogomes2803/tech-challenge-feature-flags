output "deploy_role_arn" {
  description = "Role configurada no secret AWS_DEPLOY_ROLE_ARN."
  value       = aws_iam_role.deploy.arn
}

output "provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
