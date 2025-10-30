output "alb_dns" {
  value = aws_lb.app.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}
