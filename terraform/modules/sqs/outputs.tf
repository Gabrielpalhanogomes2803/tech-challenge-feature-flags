output "queue_name" {
  value = aws_sqs_queue.this.name
}

output "queue_url" {
  value = aws_sqs_queue.this.url
}

output "queue_arn" {
  value = aws_sqs_queue.this.arn
}

output "dead_letter_queue_arn" {
  value = aws_sqs_queue.dead_letter.arn
}
