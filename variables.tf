variable "SLACK_WEBHOOK_URL" {
  description = "Slack webhook URL to send alerts"
  type        = string
  default     = "[SLACK-WEBHOOK]"
}

variable "log_group_name" {
  description = "Name of the log group to monitor"
  type        = string
  default     = "[LOG-GROUP-NAME]"
}

variable "log_group_arn" {
  description = "ARN of the log group to monitor"
  type        = string
  default     = "arn:aws:logs:us-east-1:#######:log-group:/aws/xxxxxx/xxxxxxx:*"
}
