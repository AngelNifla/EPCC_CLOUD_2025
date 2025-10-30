variable "region"           { default = "us-east-1" }
variable "instance_type"    { default = "t3.small" }   # <— antes t3.micro
variable "min_size"         { default = 1 }
variable "desired_capacity" { default = 1 }
variable "max_size"         { default = 6 }           # <— antes 4
variable "cpu_target"       { default = 25 }           # <— antes 30
