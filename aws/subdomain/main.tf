# modules/subdomain/main.tf
# Creates:
# - A Route53 subdomain for the VPC
# - An NS record in the parent domain pointing to the  subdomain


### Variables
variable "name" {
  description = "The subdomain's FQDN"
}

variable "parent_zone_id" {
  description = "The zone id of the parent domain"
}


### Outputs

output "zone_id" {
  value = "${aws_route53_zone.subdomain.zone_id}"
}


### Implementation

# Create a subdomain
resource "aws_route53_zone" "subdomain" {
  comment = "Managed by Terraform"
  name    = "${var.name}"
}

# Create NS records for the subdomain in the parent domain
resource "aws_route53_record" "subdomain_ns" {
  name    = "${var.name}"
  ttl     = "300"
  type    = "NS"
  zone_id = "${var.parent_zone_id}"
  records = [
    "${aws_route53_zone.subdomain.name_servers.0}",
    "${aws_route53_zone.subdomain.name_servers.1}",
    "${aws_route53_zone.subdomain.name_servers.2}",
    "${aws_route53_zone.subdomain.name_servers.3}"
  ]
}
