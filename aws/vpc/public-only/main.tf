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

# NOTE: Not currently implemented
variable "subnet_az_public_1" {
  description = "The availability zone for the private subnet"
}

variable "subnet_az_public_2" {
  description = "The availability zone for the public subnet"
}

variable "subnet_cidr_public_1" {
  description = "The CIDR block for the private subnet"
  default     = "172.16.0.0/24"
}

variable "subnet_cidr_public_2" {
  description = "The CIDR block for the public subnet"
  default     = "172.16.1.0/24"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "172.16.0.0/20"
}

variable "vpc_tag_name" {
  description = "The environment to which the resources belong"
}


### Outputs

output "security_group_id_public" {
  value = "${aws_security_group.public.id}"
}

output "subnet_id_public_1" {
  value = "${aws_subnet.public-1.id}"
}

output "subnet_id_public_2" {
  value = "${aws_subnet.public-2.id}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}


### Implementation

# Create a VPC into which resources are provisioned
resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  tags {
    Name = "${var.vpc_tag_name}"
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
resource "aws_subnet" "public-1" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.subnet_cidr_public_1}"
  availability_zone       = "${var.subnet_az_public_1}"
  map_public_ip_on_launch = true
  tags {
    Name        = "${var.vpc_tag_name}-public-1"
  }
}

# Create a subnet into which instances are launched
resource "aws_subnet" "public-2" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.subnet_cidr_public_2}"
  availability_zone       = "${var.subnet_az_public_2}"
  map_public_ip_on_launch = true
  tags {
    Name        = "${var.vpc_tag_name}-public-2"
  }
}

resource "aws_security_group" "public" {
  name        = "appserver"
  description = "Public Subnet Security Group"
  vpc_id      = "${aws_vpc.main.id}"
  tags {
    Name        = "${var.vpc_tag_name}-public"
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
