# modules/aws/vpc/public-only/main.tf
# Creates:
# - A VPC tagged with the Environment
# - An Internet Gateway for EC2s to reach the Internet
# - A default route in the VPCs Route Table pointing to the IGW
# - A public subnet into which to place EC2s
# - A security group with one rule allowing ssh to the public subnet
# - A Route53 subdomain for the VPC
# - An NS record in the parent domain pointing to the  subdomain


### Variables

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "172.16.0.0/20"
}

# NOTE: Not currently implemented
variable "private_cidr_block" {
  description = "The CIDR block for the private subnet"
  default     = "172.16.0.0/24"
}

variable "private_availability_zone" {
  description = "The availability zone for the private subnet"
}

variable "public_cidr_block" {
  description = "The CIDR block for the public subnet"
  default     = "172.16.1.0/24"
}

variable "public_availability_zone" {
  description = "The availability zone for the public subnet"
}

variable "environment" {
  description = "The environment to which the resources belong"
}


### Outputs

output "vpc_security_group_ids" {
  # value = ["${aws_security_group.appserver.id}"]
  value = "${aws_security_group.public.id}"
}

output "subnet_id" {
  value = "${aws_subnet.public.id}"
}

output "subnet_id_2" {
  value = "${aws_subnet.public-2.id}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}


### Implementation

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
  availability_zone       = "${var.public_availability_zone}"
  map_public_ip_on_launch = true
  tags {
    Name        = "public-${var.environment}-1"
  }
}

# Create a subnet into which instances are launched
resource "aws_subnet" "public-2" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.private_cidr_block}"
  availability_zone       = "${var.private_availability_zone}"
  map_public_ip_on_launch = true
  tags {
    Name        = "public-${var.environment}-2"
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
