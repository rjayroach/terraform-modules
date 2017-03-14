// variables


variable "create_public_subnet" { default = false }

variable "create_secondary_public_subnet" { default = false }

variable "domain" {
  description = "The parent domain for the subdomain"
}

variable "environment" {
  description = "The environment to which the resources belong"
}

variable "region" { }

variable "private_cidr_block" {
  description = "The CIDR block for the private subnet"
}

variable "public_cidr_block" {
  description = "The CIDR block for the public subnet"
}

variable "public_cidr_b_block" {
  description = "The CIDR block for the 2nd public subnet"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
}

/*
variable "primary_zone_id" {

  description = "The zone id of the parent domain"
}
*/


// outputs

output "public_subnet_id" {
  value = "${aws_subnet.public.id}"
}

output "private_subnet_id" {
  value = "${aws_subnet.private.id}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

// implementation

# Creates:
# - A VPC tagged with the Environment
# - An Internet Gateway for EC2s to reach the Internet
# - A default route in the VPCs Route Table pointing to the IGW
# - A public subnet into which to place EC2s
# - A private subnet into which to place EC2s
# - A security group with two rules allowing ping and ssh to the public subnet


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

resource "aws_subnet" "public" {
  count                   = "${var.create_public_subnet}"
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone       = "${var.region}a"
  cidr_block              = "${var.public_cidr_block}"
  map_public_ip_on_launch = true
  tags {
    Visibility = "public"
    Name = "public-${var.environment}"
  }
}

resource "aws_subnet" "public-b" {
  count                   = "${var.create_secondary_public_subnet}"
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone       = "${var.region}b"
  cidr_block              = "${var.public_cidr_b_block}"
  map_public_ip_on_launch = true
  tags {
    Name = "public-${var.environment}-b"
  }
}

# Create a subnet into which instances are launched
resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone       = "${var.region}a"
  cidr_block              = "${var.private_cidr_block}"
  map_public_ip_on_launch = true
  tags {
    Visibility = "private"
    Name = "private-${var.environment}"
  }
}
