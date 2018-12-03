variable "aws_region" {}

variable "aws_access_key" {
    type = "string"
    decscription = "Access key"
}

variable "aws_secret_key" {
    type = "string"
    description = "Secret Key"
}

#------ storage variables

variable "project_name" {}

#-------networking variables

variable "vpc_id" {}

variable "public_cidrs" {
  type = "list"
}

variable "accessip" {}

#-------compute variables

variable "key_name" {}

variable "public_key_path" {}

variable "server_instance_type" {}

variable "instance_count" {
  default = 1
}
