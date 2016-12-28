# modules/vpc/main.tf

# Create a VPC into which resources are provisioned
resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr_block}"
  tags {
    Application = "${var.application}"
    Environment = "${var.environment}"
    Name        = "${var.application}-${var.environment}"
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
    Environment = "${var.environment}"
    Name        = "public-${var.application}"
  }
}

resource "aws_security_group" "appserver" {
  name        = "appserver"
  description = "App Server Security Group"
  vpc_id      = "${aws_vpc.main.id}"
  tags {
    Environment = "${var.environment}"
    Name        = "appserver-${var.application}"
  }
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type = "ingress"
  security_group_id = "${aws_security_group.appserver.id}"

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# port 3000 from ELB
resource "aws_security_group_rule" "allow_3000_inbound" {
  type = "ingress"
  security_group_id = "${aws_security_group.appserver.id}"

  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  # TODO: only accept traffic from the ELB
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = "${aws_security_group.appserver.id}"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group" "elb" {
  name        = "appserver-elb"
  description = "ELB Security Group"
  vpc_id      = "${aws_vpc.main.id}"
  tags {
    Environment = "${var.environment}"
    Name        = "elb-${var.application}"
  }
}

resource "aws_security_group_rule" "elb_allow_https_inbound" {
  type = "ingress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "elb_allow_all_outbound" {
  type = "egress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}


# TODO: Add ALB resource
resource "aws_elb" "main" {
  name                      = "${var.application}-elb"
  security_groups           = ["${aws_security_group.elb.id}"]
  subnets                   = ["${aws_subnet.public.id}"]
  cross_zone_load_balancing = true

  listener {
    instance_port      = 3000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.server_cert_arn}"
  }

  health_check {
    healthy_threshold   = 10 
    unhealthy_threshold = 2
    timeout             = 5
    # target            = "HTTP:8000/"
    target              = "TCP:3000"
    interval            = 30
  }

  tags {
    Application = "${var.application}"
    Environment = "${var.environment}"
    Name        = "appserver"
  }
}


# Create subdomain
resource "aws_route53_zone" "subdomain" {
  name    = "${var.environment}.${var.domain}"
  comment = "Managed by Terraform"
  tags {
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

# Create an ALIAS record for the API server pointing to the ELB
resource "aws_route53_record" "elb" {
  zone_id = "${aws_route53_zone.subdomain.zone_id}"
  name    = "${var.application}-api.${var.environment}.${var.domain}"
  type    = "A"
  alias {
    name                   = "${aws_elb.main.dns_name}"
    zone_id                = "${aws_elb.main.zone_id}"
    evaluate_target_health = true
  }
}
