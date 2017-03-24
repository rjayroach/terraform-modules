# modules/subdomain/main.tf
# Creates:
# - A Route53 subdomain for the VPC
# - An NS record in the parent domain pointing to the  subdomain


### Variables

variable "create" {
  description = "Boolean value whether to create the subdomain or skip creation"
}

variable "domain_name" {
  description = "The parent domain for the subdomain"
}

variable "parent_zone_id" {
  description = "The zone id of the parent domain"
}


### Outputs

output "subdomain_zone_id" {
  value = "${aws_route53_zone.subdomain.zone_id}"
}


### Implementation

# Create a subdomain
resource "aws_route53_zone" "subdomain" {
  comment = "Managed by Terraform"
  count   = "${var.create ? 1 : 0}"
  name    = "${var.domain_name}"
}

# Create NS records for the subdomain in the parent domain
resource "aws_route53_record" "subdomain_ns" {
  count   = "${var.create ? 1 : 0}"
  name    = "${var.domain_name}."
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
