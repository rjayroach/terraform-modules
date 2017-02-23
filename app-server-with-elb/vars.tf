# modules/app-server-with-elb/vars.tf

variable "application" {
  description = "The application which these resources support"
}

variable "environment" {
  description = "The environment to which the resources belong"
}

variable "instance_type" {
  description = "The instance type for the manager and worker nodes"
}

variable "public_key" {
  description = "Contents of the public key used to connect to instances"
}

variable "region" {
  description = "The AWS region in which to provision resources"
}

variable "route53_primary_zone_id" {
  description = "The zone id to which the ELB's DNS name will be placed in"
}

variable "route53_zone_id" {
  description = "The zone id to which the ELB's DNS name will be placed in"
}

variable "route53_hostname" {
  description = "The hostname to which the ELB will be mapped to"
}

variable "server_cert_arn" {
  description = "The arn of the server certificate to install on the ELB"
}

variable "subnet_id" {
  description = "The ID of the VPC subnet"
}

variable "vpc_id" {
}

variable "vpc_security_group_ids" {
  description = "The security group ids"
}
