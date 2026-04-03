variable "table_name" {
  type        = string
  description = "dynamodb table name"
}

variable "replica_region" {
  type        = string
  description = "Region where dynamodb replica will run"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the table"
  default     = {}
}