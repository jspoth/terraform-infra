variable "table_name" {
  type        = string
  description = "DynamoDB table name"
  default     = "app_events"
}

variable "tags" {
  type        = map(string)
  default = {
    env = "dr"
  }
}
