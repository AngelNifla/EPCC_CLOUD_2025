terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# --- Datos de red existentes (VPC y subnets por defecto)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- AMI Amazon Linux 2023
data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- Seguridad
resource "aws_security_group" "cine_alb_sg" {
  name        = "cine-alb-sg"
  description = "ALB HTTP access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cine_ec2_sg" {
  name        = "cine-ec2-sg"
  description = "EC2 behind ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.cine_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- ALB + Target Group + Listener
resource "aws_lb" "cine_alb" {
  name               = "cine-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cine_alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "cine_tg" {
  name     = "cine-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "cine_http" {
  load_balancer_arn = aws_lb.cine_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cine_tg.arn
  }
}

# --- IAM Role + Instance Profile
resource "aws_iam_role" "cine_ec2_role" {
  name = "cine-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "cine_ec2_profile" {
  name = "cine-ec2-profile"
  role = aws_iam_role.cine_ec2_role.name
}

# --- Launch Template
resource "aws_launch_template" "cine_lt" {
  name_prefix   = "cine-lt-v2-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.cine_ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.cine_ec2_sg.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    server_port = 80
  }))
}

# --- Auto Scaling Group
resource "aws_autoscaling_group" "cine_asg" {
  name                      = "cine-asg"
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_type         = "ELB"
  health_check_grace_period = 90

  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.cine_tg.arn]

  launch_template {
    id      = aws_launch_template.cine_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "cine-asg"
    propagate_at_launch = true
  }
}

# --- Target Tracking por CPU
resource "aws_autoscaling_policy" "cine_cpu_target" {
  name                   = "cine-cpu-tt"
  autoscaling_group_name = aws_autoscaling_group.cine_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target
  }
}

# --- Target Tracking por Tráfico (RPS)
resource "aws_autoscaling_policy" "cine_rps_target" {
  name                   = "cine-rps-tt"
  autoscaling_group_name = aws_autoscaling_group.cine_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.cine_alb.arn_suffix}/${aws_lb_target_group.cine_tg.arn_suffix}"
    }
    target_value = var.rps_target
  }
}


######################################### === CLOUDWATCH DASHBOARD ===
resource "aws_cloudwatch_dashboard" "cine_dashboard" {
  dashboard_name = "CineTickets-AutoScaling"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0, y = 0, width = 12, height = 6,
        properties = {
          title = "CPU promedio vs DesiredCapacity",
          metrics = [
            [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.cine_asg.name, { "stat": "Average" } ],
            [ ".", "GroupDesiredCapacity", "AutoScalingGroupName", aws_autoscaling_group.cine_asg.name, { "yAxis": "right" } ]
          ],
          view = "timeSeries", stacked = false, region = var.region
        }
      },
      {
        type = "metric",
        x = 12, y = 0, width = 12, height = 6,
        properties = {
          title = "RequestCountPerTarget y 5xx",
          metrics = [
            [ "AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup", aws_lb_target_group.cine_tg.arn_suffix, "LoadBalancer", aws_lb.cine_alb.arn_suffix ],
            [ ".", "HTTPCode_Target_5XX_Count", "TargetGroup", aws_lb_target_group.cine_tg.arn_suffix, "LoadBalancer", aws_lb.cine_alb.arn_suffix ]
          ],
          view = "timeSeries", region = var.region
        }
      },
      {
        type = "metric",
        x = 0, y = 6, width = 12, height = 6,
        properties = {
          title = "Latencia promedio (TargetResponseTime)",
          metrics = [
            [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", aws_lb_target_group.cine_tg.arn_suffix, "LoadBalancer", aws_lb.cine_alb.arn_suffix ]
          ],
          view = "timeSeries", region = var.region
        }
      },
      {
        type = "metric",
        x = 12, y = 6, width = 12, height = 6,
        properties = {
          title = "Instancias en servicio",
          metrics = [
            [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.cine_asg.name ]
          ],
          view = "timeSeries", region = var.region
        }
      }
    ]
  })
}
