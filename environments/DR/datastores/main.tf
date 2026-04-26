resource "aws_ssm_parameter" "dynamodb_table_name" {
  name  = "/dr/app/dynamodb/table-name"
  type  = "String"
  value = var.table_name
  tags  = var.tags
}
