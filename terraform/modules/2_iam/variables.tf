# terraform/modules/2_iam/variables.tf

variable "project_name" {
  type = string
}
variable "data_bucket_arn" {
  type = string
}
variable "scripts_bucket_arn" {
  type = string
}
variable "aurora_secret_arn" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "aws_account_id" {
  type = string
}
variable "glue_connection_sg_id" {
  type = string
}
variable "glue_connection_subnets" {
  type = list(string)
}