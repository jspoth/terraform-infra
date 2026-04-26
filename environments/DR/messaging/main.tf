module "sqs" {
  source = "../../../modules/sqs"

  name_prefix = var.name_prefix
  queues      = var.queues
  tags        = var.tags
}

resource "aws_ssm_parameter" "queue_url" {
  for_each = var.queues

  name  = "/dr/app/sqs/${each.key}-url"
  type  = "String"
  value = module.sqs.queue_urls[each.key]
  tags  = var.tags
}
