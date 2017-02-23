# modules/vpc/main.tf
# Creates:
# - A VPC tagged with the Environment
# - An Internet Gateway for EC2s to reach the Internet
# - A default route in the VPCs Route Table pointing to the IGW
# - A public subnet into which to place EC2s
# - A security group with one rule allowing ssh to the public subnet
# - A Route53 subdomain for the VPC
# - An NS record in the parent domain pointing to the  subdomain


# Create a VPC into which resources are provisioned
resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr_block}"
  tags {
    Name = "${var.environment}"
  }
}

# Create an internet gateway to give the subnet access to the outside world
resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

# Create a subnet into which instances are launched
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_cidr_block}"
  map_public_ip_on_launch = true
  tags {
    Name        = "public-${var.environment}"
  }
}

resource "aws_security_group" "public" {
  name        = "appserver"
  description = "Public Subnet Security Group"
  vpc_id      = "${aws_vpc.main.id}"
  tags {
    Name        = "${var.environment}-public"
  }
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type = "ingress"
  security_group_id = "${aws_security_group.public.id}"

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
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
