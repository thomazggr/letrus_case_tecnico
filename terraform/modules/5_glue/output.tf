# terraform/modules/5_glue/outputs.tf

output "glue_job_performance_academica_name" {
  value = aws_glue_job.etl_performance_academica.name
}