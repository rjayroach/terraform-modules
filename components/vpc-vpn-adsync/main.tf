// variables

variable "region" {}

variable "include_public_subnet" { default = false }

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

variable "domain" {
  description = "The parent domain for the subdomain"
}

variable "environment" {
  description = "The environment to which the resources belong"
}

// outputs

// implementation

module "vpc" {
  source = "../vpc"
}

module "vpn" {
  source = "../vpn"
}

module "adsync" {
  source = "../adsync"
}
