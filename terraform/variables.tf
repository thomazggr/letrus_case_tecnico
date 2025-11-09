# terraform/variables.tf

variable "project_name" {
  description = "Nome do projeto, usado como prefixo para recursos."
  type        = string
  default     = "letrus-case"
}

variable "aws_region" {
  description = "Região da AWS para deploy dos recursos."
  type        = string
  default     = "us-east-1"
}

variable "database_name" {
  description = "Nome do banco de dados inicial no Aurora."
  type        = string
}

variable "database_user" {
  description = "Nome do usuário master do Aurora."
  type        = string
}