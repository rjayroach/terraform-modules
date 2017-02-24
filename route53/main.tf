// variables

variable "domain" {}

variable "environment" {}

variable "primary_zone_id" {}

variable "visibility" {}

// outputs

// implementation

resource "aws_route53_zone" "subdomain" {
  name    = "${var.environment}.${var.domain}"
  tags {
    Visibility    = "${var.visibility}"
    Environment = "${var.environment}"
  }
}

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
