# terraform/modules/5_glue/main.tf

# 1. Banco de dados no Glue Data Catalog
resource "aws_glue_catalog_database" "academic_db" {
  name = "${var.project_name}_academic_db"
}

# 2. Conexão Glue (para acesso VPC ao Aurora)
resource "aws_glue_connection" "aurora_jdbc" {
  name = "${var.project_name}-aurora-jdbc-connection"
  connection_type = "JDBC"

  # Os detalhes da conexão (host/porta/user/pass) serão buscados
  # pelo script no Secrets Manager.
  # Esta conexão é para o Glue saber em qual VPC/Subnet/SG rodar.
  connection_properties = {
    "JDBC_CONNECTION_URL" = "jdbc:postgresql://placeholder" # Será sobrescrito no script
    "USERNAME"            = "placeholder"
    "PASSWORD"            = "placeholder"
  }

  physical_connection_requirements {
    subnet_id         = var.glue_connection_subnets[0]
    security_group_id_list = [var.glue_connection_sg_id]
    availability_zone = data.aws_subnet.glue.availability_zone
  }
}

# Data source para pegar a AZ da subnet
data "aws_subnet" "glue" {
  id = var.glue_connection_subnets[0]
}

# 3. Glue Jobs
resource "aws_glue_job" "etl_performance_academica" {
  name     = "${var.project_name}-etl-performance-academica"
  role_arn = var.glue_role_arn
  glue_version = "5.0"
  worker_type = "G.1X"
  number_of_workers = 2
  depends_on = [
    aws_glue_catalog_database.academic_db,
    aws_glue_connection.aurora_jdbc
  ]

  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_bucket_name}/scripts/etl_performance_academica.py"
    python_version  = "3"
  }

  default_arguments = {
    "--enable-auto-scaling"  = "true"
    "--RAW_S3_PATH"          = "s3://${var.data_bucket_name}/raw/"
    "--PROCESSED_S3_PATH"    = "s3://${var.data_bucket_name}/processed/"
    "--AURORA_SECRET_ARN"    = var.aurora_secret_arn
    "--AURORA_DATABASE_NAME" = var.database_name
    "--extra-py-files"       = "s3://${var.scripts_bucket_name}/scripts/common.py"
    "--additional-python-modules" = "psycopg2-binary==2.9.9"
  }
  connections = [aws_glue_connection.aurora_jdbc.name]
}