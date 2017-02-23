# modules/s3-website/vars.tf

variable "allowed_ip" {
  description = "The IP address that may access the bucket"
}

variable "application" {
  description = "The name of the application (becomes the IAM User name)"
}

variable "bucket_name" {
  description = "The name of the S3 bucket to which the application will be deployed"
}

variable "credentials_file" {
  description = "The file name to write the bucket details and credentials"
}

variable "environment" {
  description = "The environment to which the resources belong"
}

variable "region" {
  description = "The AWS region in which to provision resources"
}

variable "route53_zone_id" {
  description = "The zone id that the bucket hostname will be placed in"
}
