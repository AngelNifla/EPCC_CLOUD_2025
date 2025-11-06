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

# --- AMI Amazon Linux 2023 (Utilizada para los nodos de EKS si es necesario)
data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- Configuración de EKS (Elastic Kubernetes Service)
# Crear el clúster EKS
resource "aws_eks_cluster" "cine_cluster" {
  name     = "cine-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [
      "subnet-0197217d14d963768", # Subnet en la zona de disponibilidad us-east-1a
      "subnet-02e788ad63d4d39d8", # Subnet en la zona de disponibilidad us-east-1b
      "subnet-057378603e0aede05", # Otra subnet, opcional
      "subnet-06089383e907edf00"  # Otra subnet, opcional
    ]
  }
}

# Tag común requerido por EKS en TODAS las subnets del cluster
resource "aws_ec2_tag" "eks_cluster_tag" {
  for_each    = toset(data.aws_subnets.default.ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/cine-cluster"
  value       = "shared"
}

# Marca TODAS las subnets como públicas para ELB (si tienes privadas, cámbialo por internal-elb allí)
resource "aws_ec2_tag" "eks_elb_role" {
  for_each    = toset(data.aws_subnets.default.ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}


# Crear el rol de IAM para EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# Crear los nodos de EKS
resource "aws_eks_node_group" "cine_node_group" {
  cluster_name    = aws_eks_cluster.cine_cluster.name
  node_group_name = "cine-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.micro"]  # Cambié de "t3.medium" a "t3.micro"
}


# Crear el rol de IAM para los nodos de EKS
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

# Permisos requeridos para los nodos administrados de EKS
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# --- Seguridad (Mantener ALB)
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

# Permite que los nodos hablen con el control plane (443)
resource "aws_security_group_rule" "allow_nodes_to_cluster_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.cine_cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.cine_k8s_sg.id
}


resource "aws_security_group" "cine_k8s_sg" {
  name        = "cine-k8s-sg"
  description = "Kubernetes instances behind ALB"
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
    interval            = 30
  }
}

resource "aws_lb_listener" "cine_listener" {
  load_balancer_arn = aws_lb.cine_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cine_tg.arn
  }
}

# --- CloudWatch Dashboard (Monitoreo)
resource "aws_cloudwatch_dashboard" "cine_dashboard" {
  dashboard_name = "cine-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0, y = 0, width = 12, height = 6,
        properties = {
          title = "CPU promedio vs DesiredCapacity",
          metrics = [
            [ "AWS/EKS", "CPUUtilization", "ClusterName", aws_eks_cluster.cine_cluster.name, { "stat": "Average" } ], # Cambiado de EC2 a EKS
            [ ".", "GroupDesiredCapacity", "ClusterName", aws_eks_cluster.cine_cluster.name, { "yAxis": "right" } ] # Cambiado de EC2 a EKS
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
      }
    ]
  })
}


