// terraform/outputs.tf


output "bucket_data_name" {
  description = "Nome do bucket S3 para dados raw, processed e scripts."
  value       = module.s3.bucket_data_name
}

output "aurora_cluster_endpoint" {
  description = "Endpoint (host) do cluster Aurora."
  value       = module.rds_aurora.cluster_endpoint
}

output "aurora_database_name" {
  description = "Nome do banco de dados no Aurora."
  value       = module.rds_aurora.database_name
}

output "secret_manager_aurora_credentials_arn" {
  description = "ARN do Secrets Manager contendo as credenciais do Aurora."
  value       = module.rds_aurora.secret_manager_arn
}

output "glue_job_performance_academica_name" {
  description = "Nome do Job Glue para ETL da performance acadêmica."
  value       = module.glue.glue_job_performance_academica_name
}