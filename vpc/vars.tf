# modules/vpc/vars.tf

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "172.16.0.0/20"
}

# NOTE: Not currently implemented
variable "private_cidr_block" {
  description = "The CIDR block for the private subnet"
  default     = "172.16.0.0/24"
}

variable "public_cidr_block" {
  description = "The CIDR block for the public subnet"
  default     = "172.16.1.0/24"
}


# variable "application" {
#   description = "The application which these resources support"
# }

variable "domain" {
  description = "The parent domain for the subdomain"
}

variable "environment" {
  description = "The environment to which the resources belong"
}

variable "primary_zone_id" {
  description = "The zone id of the parent domain"
}
