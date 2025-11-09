# terraform/modules/3_s3/outputs.tf

output "bucket_data_name" {
  value = aws_s3_bucket.data_bucket.bucket
}

output "bucket_data_arn" {
  value = aws_s3_bucket.data_bucket.arn
}
output "bucket_scripts_name" {
  value = aws_s3_bucket.scripts_bucket.bucket
}

output "bucket_scripts_arn" {
  value = aws_s3_bucket.scripts_bucket.arn
}