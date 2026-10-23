output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_arn" {
  value = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value     = aws_eks_cluster.this.certificate_authority[0].data
  sensitive = true
}

output "node_role_arn" {
  value = aws_iam_role.nodes.arn
}

output "cluster_role_arn" {
  value = aws_iam_role.cluster.arn
}

output "cluster_security_group_id" {
  description = "Security Group gerenciado pelo EKS para o cluster."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
