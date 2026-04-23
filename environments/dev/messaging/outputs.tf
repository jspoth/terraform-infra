output "queue_urls" {
  value = module.sqs.queue_urls
}

output "dlq_urls" {
  value = module.sqs.dlq_urls
}
