# modules/vpc/main.tf

# Create a VPC to launch our instances into
resource "aws_vpc" "example" {
  cidr_block = "172.16.0.0/20"
  tags {
    Application = "${var.application}"
    Environment = "${var.environment}"
    Name        = "${var.environment}"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "example" {
  vpc_id = "${aws_vpc.example.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.example.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.example.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.example.id}"
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true
  tags {
    Environment = "${var.environment}"
    Name        = "public-${var.application}"
  }
}

resource "aws_security_group" "appserver" {
  name        = "appserver"
  description = "App Server Security Group"
  vpc_id      = "${aws_vpc.example.id}"
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
  vpc_id      = "${aws_vpc.example.id}"
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


# TODO: Change to an ALB
resource "aws_elb" "example" {
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
    Name        = "appserver-elb"
  }
}
