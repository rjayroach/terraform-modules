# components/vpc-rds-ec2-elb-s3-route53/main.tf

# Component Parameters
variable "application" {}
variable "bucket_name" {}
variable "credentials_file" {}
variable "domain" {}
variable "environment" {}
variable "hostname" {}
variable "instance_type" {}
variable "public_key" {}
variable "region" {}
variable "route53_primary_zone_id" {}
variable "server_cert_arn" {}
variable "website_allowed_hosts" {}


# VPC for the exclusive use of this application
module "vpc" {
  source          = "../../aws/vpc"

  # VPC parameters
  environment     = "${var.environment}"
}


# Subdomain for the exclusive use of this application
module "subdomain" {
  source          = "../../aws/subdomain"

  # VPC parameters
  domain          = "${var.domain}"
  environment     = "${var.environment}"
  primary_zone_id = "${var.route53_primary_zone_id}"
}


# API Server
module "api-server" {
  source                 = "../../app-server-with-elb"

  # Instance parameters
  application             = "${var.application}"
  environment             = "${var.environment}"
  instance_type           = "${var.instance_type}"
  public_key              = "${var.public_key}"
  region                  = "${var.region}"
  route53_hostname        = "${var.hostname}"
  route53_primary_zone_id = "${var.route53_primary_zone_id}"
  server_cert_arn         = "${var.server_cert_arn}"
  route53_zone_id         = "${module.subdomain.subdomain_zone_id}"
  subnet_id               = "${module.vpc.subnet_id}"
  vpc_id                  = "${module.vpc.vpc_id}"
  vpc_security_group_ids  = "${module.vpc.vpc_security_group_ids}"
}


# Ember application's S3 bucket parameters
module "web-app" {
  source           = "../../s3-website"

  allowed_ip       = "${var.website_allowed_hosts}"
  application      = "${var.application}"
  bucket_name      = "${var.bucket_name}"
  credentials_file = "${var.credentials_file}"
  environment      = "${var.environment}"
  region           = "${var.region}"
  route53_zone_id  = "${module.subdomain.subdomain_zone_id}"
}
