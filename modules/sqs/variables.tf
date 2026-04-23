variable "name_prefix" {
  type        = string
  description = "Prefix applied to all queue names (e.g. 'dev'). Results in <prefix>-<name> and <prefix>-<name>-dlq."
}

variable "queues" {
  type = map(object({
    visibility_timeout = optional(number, 30)
    message_retention  = optional(number, 86400)
    max_receive_count  = optional(number, 3)
  }))
  description = "Map of queues to create. Key is the queue name suffix. Add entries in terraform.tfvars — no module changes needed."
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
