module "dynamodb" {
  source = "../../../modules/dynamodb"

  table_name     = var.table_name
  replica_region = var.replica_region
  tags           = var.tags
}
