#------networking/variables.tf

variable "vpc_id" {}

variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_region" {}
 
variable "public_cidr" {
type = "list"
}

variable "private_cidr" {
type = "list"
}

variable "proxyalb_listener_port" {}

variable "proxyalb_listener_protocol" {}

variable "proxyalb_sticky" {}
