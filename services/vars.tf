# modules/services/vars.tf

variable "region" {
  description = "The AWS region in which to provision resources"
}

variable "environment" {
  description = "The environment to which the resources belong"
}

variable "public_key" {
  description = "Contents of the public key used to connect to instances"
}

variable "instance_type" {
  description = "The instance type for the manager and worker nodes"
}

variable "vpc_security_group_ids" {
  description = "The security group ids"
}

variable "subnet_id" {
  description = "The ID of the VPC subnet"
}

variable "elb_id" {
  description = "The ID of the ELB to attach to"
}

variable "bucket_name" {
  description = "The name of the S3 bucket to which the application will be deployed"
}

variable "bucket_iam_user_arn" {
  description = "The arn of the IAM user to access this bucket"
}

variable "route53_zone_id" {
  description = "The zone id that the bucket hostname will be placed in"
}
