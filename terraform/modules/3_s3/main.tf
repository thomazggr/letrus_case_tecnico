# terraform/modules/3_s3/main.tf

resource "aws_s3_bucket" "data_bucket" {
  # Nome do bucket precisa ser único globalmente
  bucket = "${var.project_name}-data-pipeline-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "${var.project_name}-data-pipeline"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "scripts_bucket" {
  bucket = "${var.project_name}-jobs-scripts-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "${var.project_name}-jobs-scripts"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Sufixo aleatório para o nome do bucket
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Configuração de bloqueio de acesso público (Boas Práticas)
locals {
  # Mapeia os buckets criados para aplicar recursos em comum via for_each
  s3_buckets = {
    data    = aws_s3_bucket.data_bucket.id
    scripts = aws_s3_bucket.scripts_bucket.id
  }
}

# Bloqueio de acesso público aplicado a todos os buckets listados em local.s3_buckets
resource "aws_s3_bucket_public_access_block" "block" {
  for_each = local.s3_buckets

  bucket                  = each.value
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Criptografia (SSE) aplicada a todos os buckets listados em local.s3_buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  for_each = local.s3_buckets

  bucket = each.value
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "null_resource" "execute_aws_cli_sync_glue_scripts" {
  provisioner "local-exec" {
    command = "aws s3 sync ../glue_scripts/ s3://${aws_s3_bucket.scripts_bucket.bucket}/scripts/"
  }
}

resource "null_resource" "execute_aws_cli_sync_csvs" {
  provisioner "local-exec" {
    command = "aws s3 sync ../csv_exemplos/ s3://${aws_s3_bucket.data_bucket.bucket}/raw/"
  }
}