# terraform/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ----------------------------------------------------------------
# Módulo 1: Rede (VPC, Subnets, Security Groups)
# ----------------------------------------------------------------
module "networking" {
  source       = "./modules/1_networking"
  project_name = var.project_name
}

# ----------------------------------------------------------------
# Módulo 2: S3 (Bucket para dados)
# ----------------------------------------------------------------
module "s3" {
  source       = "./modules/3_s3"
  project_name = var.project_name
  # Garantir que a rede (VPC/Subnets) exista antes de criar buckets e endpoints
  depends_on   = [module.networking]
}

# ----------------------------------------------------------------
# Módulo 3: RDS Aurora (Banco de Dados)
# ----------------------------------------------------------------
module "rds_aurora" {
  source          = "./modules/4_rds_aurora"
  project_name    = var.project_name
  database_name   = var.database_name
  database_user   = var.database_user
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnets_ids
  aurora_sg_id    = module.networking.aurora_sg_id
  # O cluster depende da configuração de rede e dos buckets estarem disponíveis (por precaução)
  depends_on      = [module.networking, module.s3]
}

# ----------------------------------------------------------------
# Módulo 4: IAM (Roles para Glue)
# ----------------------------------------------------------------
module "iam" {
  source                   = "./modules/2_iam"
  project_name             = var.project_name
  data_bucket_arn          = module.s3.bucket_data_arn
  scripts_bucket_arn       = module.s3.bucket_scripts_arn
  aurora_secret_arn        = module.rds_aurora.secret_manager_arn
  aws_region               = var.aws_region
  aws_account_id           = data.aws_caller_identity.current.account_id
  glue_connection_sg_id    = module.networking.glue_sg_id
  glue_connection_subnets  = module.networking.private_subnets_ids
  # IAM depende de recursos de rede e dos buckets/secret para montar políticas corretamente
  depends_on               = [module.networking, module.s3, module.rds_aurora]
}

# ----------------------------------------------------------------
# Módulo 5: Glue (Jobs, Connection)
# ----------------------------------------------------------------
module "glue" {
  source                   = "./modules/5_glue"
  project_name             = var.project_name
  glue_role_arn            = module.iam.glue_service_role_arn
  data_bucket_name         = module.s3.bucket_data_name
  scripts_bucket_name      = module.s3.bucket_scripts_name
  database_name            = var.database_name
  aurora_secret_arn        = module.rds_aurora.secret_manager_arn
  glue_connection_subnets  = module.networking.private_subnets_ids
  glue_connection_sg_id    = module.networking.glue_sg_id
  # Glue precisa que IAM (role), buckets, rede e RDS existam primeiro
  depends_on               = [module.iam, module.s3, module.networking, module.rds_aurora]
}

# Data source para obter o Account ID
data "aws_caller_identity" "current" {}