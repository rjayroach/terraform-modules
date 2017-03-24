# modules/hostname/main.tf
# Creates:
# - A Route53 hostname


### Variables

variable "zone_id" {
  description = "The zone_id of the domain in which this hostname is created"
}

variable "name" {
  description = "The hostname to be created"
}

variable "alias_zone_id" {
  description = "The zone id of the resource being aliased"
}

variable "alias_name" {
  description = "The name of the resource being aliased"
}


### Implementation

# Create an ALIAS record for the resource (ELB, S3 website, etc)
resource "aws_route53_record" "hostanme" {
  zone_id = "${var.zone_id}"
  name    = "${var.name}"
  type    = "A"
  alias {
    name                   = "${var.alias_name}"
    zone_id                = "${var.alias_zone_id}"
    evaluate_target_health = true
  }
}
