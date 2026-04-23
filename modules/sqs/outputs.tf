output "queue_urls" {
  value       = { for k, q in aws_sqs_queue.this : k => q.url }
  description = "Map of queue name suffix to SQS queue URL"
}

output "queue_arns" {
  value       = { for k, q in aws_sqs_queue.this : k => q.arn }
  description = "Map of queue name suffix to SQS queue ARN"
}

output "dlq_urls" {
  value       = { for k, q in aws_sqs_queue.dlq : k => q.url }
  description = "Map of queue name suffix to DLQ URL"
}

output "dlq_arns" {
  value       = { for k, q in aws_sqs_queue.dlq : k => q.arn }
  description = "Map of queue name suffix to DLQ ARN"
}
