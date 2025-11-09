// Backend remoto S3 para armazenar somente o arquivo de state.
// Observações:
// - Este arquivo aponta para um bucket S3 nomeado a partir de `project_name`.
// - O bucket precisa existir antes de executar `terraform init`.
// - Se preferir não hardcodar valores, execute `terraform init -backend-config=...` com os valores desejados.

terraform {
  backend "s3" {
    # Bucket S3 que armazenará o state. Crie o bucket manualmente ou ajuste conforme necessário.
    bucket = "letrus-de-case-terraform-state"

    # Caminho/arquivo do state dentro do bucket
    key    = "global/terraform.tfstate"

    # Região do bucket
    region = "us-east-1"

    # Criptografa o objeto no S3
    encrypt = true
  }
}
