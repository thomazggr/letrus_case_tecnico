# terraform/modules/4_rds_aurora/outputs.tf

output "cluster_endpoint" {
  description = "Endpoint de escrita do cluster Aurora"
  value       = aws_rds_cluster.aurora.endpoint
}

output "database_name" {
  description = "Nome do banco de dados"
  value       = aws_rds_cluster.aurora.database_name
}

output "secret_manager_arn" {
  description = "ARN do Secret com as credenciais"
  value       = data.aws_secretsmanager_secret.aurora_credentials.arn
}