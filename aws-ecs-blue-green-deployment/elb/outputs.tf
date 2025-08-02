
output "dns_name" {
  value = aws_lb.main.dns_name
}

output "listener_rule_arn" {
  value = aws_lb_listener_rule.main.arn
}

output "target_group_arns" {
  value = aws_lb_target_group.main[*].arn
}
