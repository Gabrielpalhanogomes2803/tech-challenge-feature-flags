output "vpc_id" {
  description = "ID da VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas."
  value       = module.network.private_subnet_ids
}

output "ecr_repository_urls" {
  description = "URLs dos cinco repositórios ECR."
  value       = module.ecr.repository_urls
}

output "dynamodb_table_name" {
  description = "Nome da tabela de analytics."
  value       = module.dynamodb.table_name
}

output "sqs_queue_url" {
  description = "URL da fila de analytics."
  value       = module.sqs.queue_url
}

output "sqs_queue_arn" {
  description = "ARN da fila de analytics."
  value       = module.sqs.queue_arn
}

output "rds_endpoints" {
  description = "Endpoints das três instâncias PostgreSQL."
  value       = module.database.endpoints
}

output "rds_database_names" {
  description = "Nomes dos bancos PostgreSQL."
  value       = module.database.database_names
}

output "rds_master_secret_arns" {
  description = "Secrets das credenciais gerenciadas pelo RDS."
  value       = module.database.master_user_secret_arns
  sensitive   = true
}

output "redis_endpoint" {
  description = "Endpoint primário do Redis."
  value       = module.redis.primary_endpoint
}

output "redis_port" {
  description = "Porta do Redis."
  value       = module.redis.port
}


output "eks_cluster_name" {
  description = "Nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint da API Kubernetes."
  value       = module.eks.cluster_endpoint
}

output "eks_node_role_arn" {
  description = "ARN da role dos nodes."
  value       = module.eks.node_role_arn
}
