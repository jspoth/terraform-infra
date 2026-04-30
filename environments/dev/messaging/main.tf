module "sqs" {
  source = "../../../modules/sqs"

  name_prefix = var.name_prefix
  queues      = var.queues
  tags        = var.tags
}

resource "aws_ssm_parameter" "queue_url" {
  for_each = var.queues

  name  = "/dev/app/sqs/${each.key}-url"
  type  = "String"
  value = module.sqs.queue_urls[each.key]
  tags  = var.tags
}

# ── SNS ──────────────────────────────────────────────────────────────────────

resource "aws_sns_topic" "cost_optimizer_alerts" {
  name = "dev-cost-optimizer-alerts"
  tags = var.tags
}

data "sops_file" "secrets" {
  source_file = "secrets.enc.yaml"
}

resource "aws_sns_topic_subscription" "cost_optimizer_email" {
  topic_arn = aws_sns_topic.cost_optimizer_alerts.arn
  protocol  = "email"
  endpoint  = data.sops_file.secrets.data["alert_email"]
}

resource "aws_ssm_parameter" "sns_topic_arn" {
  name  = "/dev/app/cost-optimizer/sns-topic-arn"
  type  = "String"
  value = aws_sns_topic.cost_optimizer_alerts.arn
  tags  = var.tags
}
