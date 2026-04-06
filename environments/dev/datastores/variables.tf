variable "table_name" {
  type        = string
  description = "DynamoDB table name"
  default     = "app_events"
}

variable "replica_region" {
  type        = string
  description = "Region where DynamoDB replica will run"
  default     = "us-west-2"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the table"
  default = {
    env = "dev"
  }
}
