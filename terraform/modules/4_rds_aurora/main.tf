# terraform/modules/4_rds_aurora/main.tf

# 1. Subnet Group para o Cluster
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-aurora-sng"
  subnet_ids = var.private_subnets
  tags = {
    Name = "${var.project_name}-aurora-sng"
  }
}

# 2. Cluster Aurora PostgreSQL
resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${var.project_name}-aurora-cluster"
  engine                          = "aurora-postgresql"
  engine_version                  = "15.5" # Use uma versão recente
  database_name                   = var.database_name
  master_username                 = var.database_user
  manage_master_user_password     = true # Deixa o AWS gerenciar a senha no Secrets Manager
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  vpc_security_group_ids          = [var.aurora_sg_id]
  storage_encrypted               = true
  skip_final_snapshot             = true
  # Define o Secret Manager para armazenar a senha
  master_user_secret_kms_key_id   = aws_kms_key.aurora_secret.key_id
  
  # Garantir que o subnet group e a chave KMS existam antes de criar o cluster
  depends_on = [
    aws_db_subnet_group.aurora,
    aws_kms_key.aurora_secret
  ]
}

# 3. Instância do Cluster (apenas 1 para o teste)
resource "aws_rds_cluster_instance" "aurora" {
  cluster_identifier = aws_rds_cluster.aurora.id
  identifier         = "${var.project_name}-aurora-instance"
  instance_class     = "db.t3.medium" # Custo-benefício para testes
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
  # As instâncias devem ser criadas somente após o cluster existir
  depends_on = [aws_rds_cluster.aurora]
}

# 4. Chave KMS para criptografar o Secret
resource "aws_kms_key" "aurora_secret" {
  description             = "KMS key for Aurora ${var.project_name} secret"
  enable_key_rotation     = true
}

# Data source para obter o ARN do secret gerado
data "aws_secretsmanager_secret" "aurora_credentials" {
  arn = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
  # Garantir que o cluster (que cria o secret) exista antes de ler o secret
  depends_on = [aws_rds_cluster.aurora]
}