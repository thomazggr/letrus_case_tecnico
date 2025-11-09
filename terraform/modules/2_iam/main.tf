# terraform/modules/2_iam/main.tf

# Role para o serviço do Glue
resource "aws_iam_role" "glue_service_role" {
  name = "${var.project_name}-glue-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# Política customizada para o Glue
resource "aws_iam_policy" "glue_policy" {
  name   = "${var.project_name}-glue-policy"
  policy = data.aws_iam_policy_document.glue_policy_doc.json
}

# Anexa a política à role
resource "aws_iam_role_policy_attachment" "glue_policy_attach" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
  # Garantir que role e policy existam antes de anexar
  depends_on = [aws_iam_role.glue_service_role, aws_iam_policy.glue_policy]
}

# Anexa política gerenciada (para acesso ao Glue, S3, EC2 - este último para VPC)
resource "aws_iam_role_policy_attachment" "glue_managed_policy_attach" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  depends_on = [aws_iam_role.glue_service_role]
}

# Anexa política gerenciada (para acesso VPC do Glue Job)
resource "aws_iam_role_policy_attachment" "glue_vpc_policy_attach" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  depends_on = [aws_iam_role.glue_service_role]
}


# Documento da Política IAM (Least Privilege)
data "aws_iam_policy_document" "glue_policy_doc" {

  # Acesso ao S3 (Leitura do RAW, Escrita no PROCESSED/TEMP/SCRIPTS)
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${var.data_bucket_arn}/raw/*",
      "${var.data_bucket_arn}/processed/*",
      "${var.data_bucket_arn}/temp/*",
      "${var.scripts_bucket_arn}/*"
    ]
  }
  
  # Acesso de Listagem no Bucket
  statement {
    actions   = ["s3:ListBucket"]
    resources = [var.data_bucket_arn, var.scripts_bucket_arn]
  }

  # Acesso ao Secrets Manager (para pegar a senha do Aurora)
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.aurora_secret_arn]
  }

  # Acesso ao CloudWatch Logs (Diferencial)
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws-glue/jobs/*"]
  }

  # Acesso à Rede (Necessário para rodar na VPC)
  statement {
    actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:AssignPrivateIpAddresses",
        "ec2:UnassignPrivateIpAddresses"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:network-interface/*",
      "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:subnet/${join("\", \"arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:subnet/", var.glue_connection_subnets)}",
      "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:security-group/${var.glue_connection_sg_id}"
    ]
  }
}