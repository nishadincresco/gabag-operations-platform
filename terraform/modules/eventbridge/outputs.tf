output "rule_arn" {
  value = aws_cloudwatch_event_rule.cron_job.arn
}

output "api_destination_arn" {
  value = aws_cloudwatch_event_api_destination.cron_job.arn
}
