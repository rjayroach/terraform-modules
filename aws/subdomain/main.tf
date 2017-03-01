# modules/subdomain/main.tf
# Creates:
# - A Route53 subdomain for the VPC
# - An NS record in the parent domain pointing to the  subdomain

variable "domain" {
  description = "The parent domain for the subdomain"
}

variable "environment" {
  description = "The environment to which the resources belong"
}

variable "primary_zone_id" {
  description = "The zone id of the parent domain"
}


output "subdomain_zone_id" {
  value = "${aws_route53_zone.subdomain.zone_id}"
}


# TODO: this should probably be separated out to another template
# Create a subdomain for the VPC
resource "aws_route53_zone" "subdomain" {
  name    = "${var.environment}.${var.domain}"
  comment = "Managed by Terraform"
  tags {
    Environment = "${var.environment}"
  }
}

# TODO: this would also be separated out
# Create NS records for the subdomain in the parent domain
resource "aws_route53_record" "subdomain_ns" {
  zone_id = "${var.primary_zone_id}"
  name    = "${var.environment}.${var.domain}."
  type    = "NS"
  ttl     = "300"
  records = [
    "${aws_route53_zone.subdomain.name_servers.0}",
    "${aws_route53_zone.subdomain.name_servers.1}",
    "${aws_route53_zone.subdomain.name_servers.2}",
    "${aws_route53_zone.subdomain.name_servers.3}"
  ]
}
