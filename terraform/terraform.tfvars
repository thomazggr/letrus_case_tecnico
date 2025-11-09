# terraform/terraform.tfvars

# Nome geral do projeto (será usado como prefixo)
project_name = "letrus-de-case"

# Região da AWS para deploy
aws_region = "us-east-1"

# Nome do banco de dados a ser criado no cluster Aurora
database_name = "letrusdb"

# Nome de usuário master para o Aurora (a senha será gerada)
database_user = "adminletrus"