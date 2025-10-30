output "alb_dns" {
  value = aws_lb.cine_alb.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.cine_asg.name
}
