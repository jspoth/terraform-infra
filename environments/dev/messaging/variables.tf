variable "region" {
  type        = string
  description = "AWS region"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for all queue names. Must match sqs_queue_prefix in permissions/terraform.tfvars."
}

variable "queues" {
  type = map(object({
    visibility_timeout = optional(number, 30)
    message_retention  = optional(number, 86400)
    max_receive_count  = optional(number, 3)
  }))
  description = "Queues to create. Add a new entry here to provision a queue + DLQ pair — no other files need to change."
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
