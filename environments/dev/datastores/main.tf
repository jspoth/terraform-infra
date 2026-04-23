module "dynamodb" {
  source = "../../../modules/dynamodb"

  table_name     = var.table_name
  replica_region = var.replica_region
  tags           = var.tags
}

resource "aws_ssm_parameter" "dynamodb_table_name" {
  name  = "/dev/app/dynamodb/table-name"
  type  = "String"
  value = module.dynamodb.table_name
  tags  = var.tags
}
