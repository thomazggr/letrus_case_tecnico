# terraform/modules/1_networking/main.tf

# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 2. Subnets (2 privadas para DB e Glue)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
  # Garantir que a VPC exista antes de criar subnets
  depends_on = [aws_vpc.main]
}

# 3. S3 Gateway Endpoint (Permite que Glue e RDS acessem S3 de dentro da VPC)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids   = [aws_route_table.private.id]
  # As rotas/route table devem existir antes de criar o endpoint do S3
  depends_on = [aws_route_table.private]
}

# 4. Glue Interface Endpoint (Permite que Glue acesse a API do Glue)
resource "aws_vpc_endpoint" "glue" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.glue"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.glue_sg.id]
  private_dns_enabled = true
  # Endpoints de interface precisam das subnets e security group
  depends_on = [aws_subnet.private, aws_security_group.glue_sg]
}

# 5. Roteamento para Subnets Privadas (necessário para o S3 Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
  # Garantir que a route table e as subnets existam antes de associar
  depends_on = [aws_route_table.private, aws_subnet.private]
}

# 6. Security Groups
# SG para o Aurora: Permite entrada na porta 5432 (Postgres) vindo do SG do Glue
resource "aws_security_group" "aurora_sg" {
  name        = "${var.project_name}-aurora-sg"
  description = "Permite acesso ao Aurora pelo Glue"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.glue_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG para o Glue: Permite toda saída (para acessar S3, Secrets Manager e Aurora)
resource "aws_security_group" "glue_sg" {
  name        = "${var.project_name}-glue-sg"
  description = "Permite acesso do Glue aos recursos da VPC"
  vpc_id      = aws_vpc.main.id

  # Permite que o Glue acesse ele mesmo (necessário para endpoints de interface)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Data sources
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}