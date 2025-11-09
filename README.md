# Case Técnico de Engenharia de Dados - Letrus

## 🎯 Objetivo

Centralizar dados acadêmicos em uma arquitetura simples e eficiente: um único ETL unificado (AWS Glue) que lê os arquivos fonte, gera uma tabela desnormalizada e persiste o resultado no S3 (Parquet) e no Amazon Aurora (PostgreSQL).

---

## 🏗️ Diagrama da Arquitetura (simplificada)

```text
┌────────────┐    ┌──────────────┐    ┌──────────────────────────┐    ┌───────────────┐
│ CSV Local  │──▶ │ S3 (raw)     │──▶ │ Glue Job único:          │──▶ │ S3 (processed)│
└────────────┘    └──────────────┘    │ etl_performance_academica│    └───────────────┘
                                         │                         
                                         ▼
                                    ┌──────────────┐
                                    │ Aurora (RDS) │
                                    └──────────────┘

Outros componentes:
- CloudWatch Logs: logs do Glue Job.
- Secrets Manager: credenciais do Aurora.
```

---

## 📂 Estrutura de Arquivos
letrus-data-case/ 
├── terraform/ 
│ ├── modules/ 
│ │ ├── 1_networking/ 
│ │ ├── 2_iam/ 
│ │ ├── 3_s3/ 
│ │ ├── 4_rds_aurora/ 
│ │ └── 5_glue/ 
│ ├── main.tf 
│ ├── variables.tf 
│ ├── outputs.tf 
│ └── terraform.tfvars 
├── glue_scripts/ 
│ ├── etl_performance_academica.py 
│ └── common.py
├── sql/ 
│ ├── 01_create_tables.sql 
│ └── 02_analysis_queries.sql 
├── csv_exemplos/ 
│ ├── alunos.csv 
│ ├── escolas.csv 
│ └── notas.csv 
└── README.md

---

## 🛠️ Tecnologias Utilizadas

* **Infraestrutura como Código:** Terraform
* **Armazenamento:** Amazon S3, Amazon Aurora (PostgreSQL)
* **ETL e Orquestração:** AWS Glue (um único Job)
* **Segurança:** AWS IAM, AWS Secrets Manager
* **Monitoramento:** AWS CloudWatch
* **Linguagens:** Python (PySpark), SQL

---

## 🚀 Passo a Passo da Execução

### 1. Pré-requisitos

* Conta AWS configurada com credenciais (AWS CLI).
* Terraform instalado.
* Um cliente SQL (DBeaver, DataGrip, psql) para conectar ao Aurora.

#### Backend remoto (S3) — criação do bucket

O backend do Terraform neste projeto está configurado para armazenar o state em um bucket S3. O arquivo `terraform/backend.tf` referencia o bucket atual:

```
bucket = "letrus-de-case-terraform-state"
key    = "global/terraform.tfstate"
region = "us-east-1"
```

Esse bucket precisa existir antes de executar `terraform init`. Abaixo há comandos AWS CLI (PowerShell) para criar o bucket, habilitar criptografia padrão.

Observações rápidas:
- Substitua `letrus-de-case-terraform-state` por um nome globalmente único se necessário.

Exemplos (sh / AWS CLI):

```sh
# 1) Criar bucket em us-east-1
aws s3api create-bucket --bucket letrus-de-case-terraform-state --region us-east-1

# 2) Habilitar criptografia padrão (server-side encryption AES256)
aws s3api put-bucket-encryption --bucket letrus-de-case-terraform-state --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

Depois de criar o bucket continue os passos. 

### 2. Deploy da Infraestrutura (Terraform)

1. Clone este repositório.
2. Preencha as variáveis (ex: `project_name` e `region`).
3. Navegue até o diretório `terraform/` e execute:

    ```powershell
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

4. Aguarde o provisionamento (VPC, S3, Aurora e Glue).
5. **Anote os outputs importantes** exibidos pelo Terraform:
    * `bucket_data_name` — nome do bucket S3.
    * `aurora_cluster_endpoint` — host do banco.
    * `secret_manager_aurora_credentials_arn` — ARN do secret com credenciais do DB.
    * `glue_job_performance_academica_name` — nome do Glue Job único.

### 3. Execução do Pipeline (Glue Job único)

1. **Preparar o Banco de Dados (Primeira vez):**
    - No AWS Secrets Manager, obtenha o secret (`secret_manager_aurora_credentials_arn`).
    - Conecte-se ao Aurora e execute `sql/01_create_tables.sql` para criar a tabela desnormalizada `performance_academica`.

2. **Executar o Glue Job:**
    - No console AWS Glue (ou via API), execute o job `${project_name}-etl-performance-academica`.
    - O job lê os CSVs de `raw/` (`alunos.csv`, `escolas.csv`, `notas.csv`), gera a tabela desnormalizada, grava Parquet em `processed/performance_academica/<run>` e faz upsert no Aurora.
    - O upsert usa chave composta `(aluno_id, escola_id, disciplina)` para permitir múltiplas linhas por aluno/disciplinas.

### 4. Consultas no Aurora

* Execute as queries em `sql/02_analysis_queries.sql` para análises sobre `performance_academica`.
