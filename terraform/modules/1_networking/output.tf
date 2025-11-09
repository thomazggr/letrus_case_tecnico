# terraform/modules/1_networking/outputs.tf

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnets_ids" {
  value = aws_subnet.private[*].id
}

output "aurora_sg_id" {
  value = aws_security_group.aurora_sg.id
}

output "glue_sg_id" {
  value = aws_security_group.glue_sg.id
}