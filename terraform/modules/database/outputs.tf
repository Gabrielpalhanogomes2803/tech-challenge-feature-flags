output "endpoints" {
  description = "Endpoints dos bancos PostgreSQL."
  value       = { for name, database in aws_db_instance.this : name => database.address }
}

output "ports" {
  value = { for name, database in aws_db_instance.this : name => database.port }
}

output "database_names" {
  value = { for name, database in aws_db_instance.this : name => database.db_name }
}

output "master_user_secret_arns" {
  description = "ARNs dos secrets gerenciados pelo RDS."
  value = {
    for name, database in aws_db_instance.this :
    name => try(database.master_user_secret[0].secret_arn, null)
  }
  sensitive = true
}

output "security_group_id" {
  value = aws_security_group.this.id
}
