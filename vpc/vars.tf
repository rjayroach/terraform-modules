# modules/vpc/vars.tf

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "172.16.0.0/20"
}

variable "private_cidr_block" {
  description = "The CIDR block for the private subnet"
  default     = "172.16.0.0/24"
}

variable "public_cidr_block" {
  description = "The CIDR block for the public subnet"
  default     = "172.16.1.0/24"
}


variable "environment" {
  description = "The environment to which the resources belong"
}

variable "application" {
  description = "The application which these resources support"
}

variable "server_cert_arn" {
  description = "The arn of the server certificate to install on the ELB"
}

variable "domain" {
  description = "The parent domain for the subdomain"
}

variable "primary_zone_id" {
  description = "The zone id of the parent domain"
}
