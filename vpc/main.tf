// variables

variable "aws_region" { }

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "172.16.0.0/20"
}

# NOTE: Not currently implemented
variable "private_cidr_block" {
  description = "The CIDR block for the private subnet"
  default     = "172.16.0.0/24"
}

variable "public_cidr_block" {
  description = "The CIDR block for the public subnet"
  default     = "172.16.1.0/24"
}

variable "domain" {
  description = "The parent domain for the subdomain"
}

variable "environment" {
  description = "The environment to which the resources belong"
}

/*
variable "primary_zone_id" {

  description = "The zone id of the parent domain"
}
*/

// outputs

output "vpc_security_group_ids" {
  # value = ["${aws_security_group.appserver.id}"]
  value = "${module.global-allow.group_id}"
}

output "subnet_id" {
  value = "${aws_subnet.public.id}"
}

/*
output "subdomain_zone_id" {
  value = "${module.route53.subdomain.zone_id}"
}
*/

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

// implementation

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
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "${var.public_cidr_block}"
  map_public_ip_on_launch = true
  tags {
    Visibility = "public"
    Name = "public-${var.environment}"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "${var.private_cidr_block}"
  map_public_ip_on_launch = true
  tags {
    Visibility = "private"
    Name = "private-${var.environment}"
  }
}

/*
resource "aws_subnet" "public-b" {
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone       = "${var.aws_region}b"
  cidr_block              = "${var.public_cidr_b_block}"
  map_public_ip_on_launch = true
  tags {
    Name = "public-${var.environment}"
  }
}
*/

/*
module "adsync" {
  source          = "../adsync"
  vpc_id          = "${aws_vpc.main.id}"
  domain          = "${var.domain}"
  adsync_password = "super_secret"
}
*/

module "global-allow" {
  source = "../sec-groups"
  vpc_id = "${aws_vpc.main.id}"
  environment = "${var.environment}"
}

module "vpn" {
  source = "../vpn"
  vpc_id = "${aws_vpc.main.id}"
}

/*
module "route53" {
  source = "../route53"
}
*/
