#------networking/variables.tf

variable "vpc_id" {}

variable "public_cidrs" {
  type = "list"
}

variable "accessip" {}
