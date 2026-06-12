resource "aws_iam_role" "eventbridge_invoke" {
  name = "${var.name_suffix}-eventbridge-invoke"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "eventbridge_invoke" {
  name = "${var.name_suffix}-invoke-api-destination"
  role = aws_iam_role.eventbridge_invoke.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "events:InvokeApiDestination"
      Resource = aws_cloudwatch_event_api_destination.cron_job.arn
    }]
  })
}

resource "aws_cloudwatch_event_connection" "cron" {
  name               = "${var.name_suffix}-cron"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "Authorization"
      value = "Bearer ${var.cron_secret}"
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "cron_job" {
  name                             = "${var.name_suffix}-cron-job"
  connection_arn                   = aws_cloudwatch_event_connection.cron.arn
  invocation_endpoint              = "${trim(var.cron_endpoint_url, "/")}${var.api_path}"
  http_method                      = "POST"
  invocation_rate_limit_per_second = 10
}

resource "aws_cloudwatch_event_rule" "cron_job" {
  name                = "${var.name_suffix}-cron-job"
  description         = "Scheduled cron trigger → ${var.api_path}"
  schedule_expression = var.schedule_expression

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "cron_job" {
  rule      = aws_cloudwatch_event_rule.cron_job.name
  target_id = "cron-job-target"
  arn       = aws_cloudwatch_event_api_destination.cron_job.arn
  role_arn  = aws_iam_role.eventbridge_invoke.arn

  input = jsonencode({})
}
