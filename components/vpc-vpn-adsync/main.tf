// variables

variable "domain" {}

variable "environment" { default = "development" }

variable "password" {}

variable "private_cidr_block" {}

variable "public_cidr_block" {}

variable "public_cidr_b_block" {}

variable "region" {}

variable "vpc_cidr_block" {}


// outputs

output "default_security_group_ids" { value = [ "${module.global-allow.group_id}" ]}

output "private_subnet_id" { value = "${module.vpc.private_subnet_id}" }

output "public_subnet_id" { value = "${module.vpc.public_subnet_id}" }

/*
output "subdomain_zone_id" {
  value = "${module.dns.subdomain.zone_id}"
}
*/

output "vpc_id" { value = "${module.vpc.vpc_id}" }


// implementation

# module "adsync" {
#   source          = "../../modules/adsync"

#   adsync_password = "${var.password}"
#   domain          = "${var.domain}"
#   subnet_ids      = [ "${module.vpc.private_subnet_id}"]
#   vpc_id          = "${module.vpc.vpc_id}"
# }

# module "dns" {
#   source = "../../modules/route53"
# }

module "global-allow" {
  source = "../../modules/sec-groups-global-allow"

  environment = "${var.environment}"
  vpc_id      = "${module.vpc.vpc_id}"
}

module "vpc" {
  source      = "../../modules/vpc"

  domain              = "${var.domain}"
  environment         = "${var.environment}"
  private_cidr_block  = "${var.private_cidr_block}"
  public_cidr_block   = "${var.public_cidr_block}"
  public_cidr_b_block = "${var.public_cidr_b_block}"
  region              = "${var.region}"
  vpc_cidr_block      = "${var.vpc_cidr_block}"
}

# module "vpn" {
#   source = "../../modules/vpn"

#   vpc_id = "${module.vpc.vpc_id}"
# }
