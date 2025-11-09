# terraform/modules/5_glue/variables.tf

variable "project_name" {
  type = string
}
variable "glue_role_arn" {
  type = string
}
variable "data_bucket_name" {
  type = string
}
variable "scripts_bucket_name" {
  type = string
}
variable "database_name" {
  type = string
}
variable "aurora_secret_arn" {
  type = string
}
variable "glue_connection_subnets" {
  type = list(string)
}
variable "glue_connection_sg_id" {
  type = string
}