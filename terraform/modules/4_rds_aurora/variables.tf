# terraform/modules/4_rds_aurora/variables.tf

variable "project_name" {
  type = string
}
variable "database_name" {
  type = string
}
variable "database_user" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}
variable "aurora_sg_id" {
  type = string
}