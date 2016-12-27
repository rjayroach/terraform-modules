# modules/vpc/vars.tf

variable "environment" {
  description = "The environment to which the resources belong"
}

variable "application" {
  description = "The application which these resources support"
}

variable "server_cert_arn" {
  description = "The arn of the server certificate to install on the ELB"
}
