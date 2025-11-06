variable "region"           { default = "us-east-1" }
variable "instance_type"    { default = "t3.small" }
variable "min_size"         { default = 1 }
variable "desired_capacity" { default = 1 }
variable "max_size"         { default = 4 }
variable "cpu_target"       { default = 30 }
variable "rps_target"       { default = 100 }
