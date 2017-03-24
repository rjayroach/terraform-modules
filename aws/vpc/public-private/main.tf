# modules/aws/vpc/public-private/main.tf
# Reverse compiled using terraforming against a vanilla AWS VPC created by Wizard
# Creates:
# - A VPC with public and private subnets

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags {}
}

resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = false

  tags {
    "Name" = "Private subnet"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = false

  tags {
    "Name" = "Public subnet"
  }
}

resource "aws_network_acl" "main" {
  vpc_id                  = "${aws_vpc.main.id}"
  subnet_ids = ["${aws_subnet.private.id}", "${aws_subnet.public.id}"]

  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags {}
}

resource "aws_internet_gateway" "main" {
  vpc_id                  = "${aws_vpc.main.id}"

  tags {}
}



resource "aws_vpn_gateway" "main" {
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone = ""
  tags {}
}

resource "aws_route_table" "vgw" {
  vpc_id                  = "${aws_vpc.main.id}"

  propagating_vgws = ["${aws_vpn_gateway.main.id}"]

  tags {}
}

resource "aws_route_table" "igw" {
  vpc_id                  = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {}
}

resource "aws_route_table_association" "igw-public" {
  route_table_id = "${aws_route_table.igw.id}"
  subnet_id = "${aws_subnet.public.id}"
}


resource "aws_security_group" "main" {
  name        = "default"
  description = "default VPC security group"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = []
    self            = true
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

}
