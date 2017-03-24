# modules/aws/vpc/public-private-vpn/main.tf
# Reverse compiled using terraforming against a production AWS VPC created by Wizard
# Creates:


### Variables

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

# NOTE: Not currently implemented
variable "private_cidr_block" {
  description = "The CIDR block for the private subnet"
  default     = "10.0.1.0/24"
}

variable "public_cidr_block" {
  description = "The CIDR block for the public subnet"
  default     = "10.0.0.0/24"
}

variable "environment" {
  description = "The environment to which the resources belong"
}


### Outputs

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "subnet_id" {
  value = "${aws_subnet.public.id}"
}

output "vpc_security_group_ids" {
  # value = ["${aws_security_group.appserver.id}"]
  value = "${aws_security_group.bastion-host-inbound-from-internet.id}"
}



### Implementation

resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr_block}"
  enable_dns_hostnames = false
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags {
    "Name" = "production"
  }
}

resource "aws_vpn_gateway" "main" {
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone = ""
  tags {
    "Environment" = "production"
    "Application" = "recheck"
    "Name" = "office-vpn"
  }
}

# subnet-61d8b628-subnet-61d8b628
resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.private_cidr_block}"
  # availability_zone       = "us-east-1d"
  map_public_ip_on_launch = false
  tags {}
}

# subnet-60d8b629-subnet-60d8b629
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_cidr_block}"
  # availability_zone       = "us-east-1d"
  map_public_ip_on_launch = false
  tags {}
}


# Allow private subnet to access Internet (igw-a3d369c4)
resource "aws_internet_gateway" "main" {
  vpc_id                  = "${aws_vpc.main.id}"
  tags {}
}


# Routing for private subnet to access the Internet (rtb-11587a77)
resource "aws_route_table" "custom-route-table" {
  vpc_id                  = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  propagating_vgws = ["${aws_vpn_gateway.main.id}"]

  tags {
    "Environment" = "production"
    "Application" = "recheck"
    "Name" = "custom-route-table"
  }
}


# NOTE: Not sure what this is doing. In AWS console it doesn't seem to have any associations (rtb-12587a74)
resource "aws_route_table" "what-is-this-doing" {
  vpc_id                  = "${aws_vpc.main.id}"
  tags {}
}


# Route Table (rtb-e8b26291) for the remote side of the VPN (vgw-41d23b28)
resource "aws_route_table" "main-route-table" {
  vpc_id                  = "${aws_vpc.main.id}"

  route {
    cidr_block = "192.168.1.0/24"
    gateway_id = "${aws_vpn_gateway.main.id}"
  }

  route {
    cidr_block = "0.0.0.0/0"
  }

  tags {
    "Application" = "recheck"
    "Environment" = "production"
    "Name" = "main-route-table"
  }
}



resource "aws_route_table_association" "custom-route-table-rtbassoc-b74376ce" {
  route_table_id = "${aws_route_table.custom-route-table.id}"
  subnet_id     = "${aws_subnet.public.id}"
}

resource "aws_route_table_association" "main-route-table-rtbassoc-fde75d85" {
  route_table_id = "${aws_route_table.main-route-table.id}"
  subnet_id     = "${aws_subnet.private.id}"
}


# sg-7aa62a06
resource "aws_security_group" "bastion-host-inbound-from-internet" {
  name        = "bastion-host-inbound-from-internet"
  description = "Bastion host inbound from internet"
  vpc_id                  = "${aws_vpc.main.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["27.125.142.130/32"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


# sg-b5a428c9
resource "aws_security_group" "bastion-host-internal-interface" {
  name        = "bastion-host-internal-interface"
  description = "public subnet to private subnet communications"
  vpc_id                  = "${aws_vpc.main.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


# sg-a4c349d9
resource "aws_security_group" "default" {
  name        = "default"
  description = "default VPC security group"
  vpc_id                  = "${aws_vpc.main.id}"

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


# sg-326b184f
resource "aws_security_group" "launch-wizard" {
  name        = "launch-wizard-2"
  description = "launch-wizard-2"
  vpc_id                  = "${aws_vpc.main.id}"

  # Allows connections from other machines in the private subnet and from the remote VPN network
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["10.0.1.0/24", "192.168.1.0/24"]
  }

  # Allows ssh connection from bastion host in public subnet to API Server in private subnet
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion-host-inbound-from-internet.id}"]
    self            = false
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


# Connects to API server instance in the private subnet (move out of the VPC definition to recheck)
resource "aws_network_interface" "eni-c63ca427" {
  subnet_id         = "${aws_subnet.private.id}"
  private_ips       = ["10.0.1.118"]
  security_groups   = ["${aws_security_group.launch-wizard.id}"]
  source_dest_check = true
  attachment {
    instance     = "i-0fc07a3f95e217ddf"
    device_index = 0
  }
}


# Interface for NAT Gateway nat-088dc4a463bf72e6e (eni-dd7de63c)
resource "aws_network_interface" "nat-gateway" {
  subnet_id         = "${aws_subnet.public.id}"
  private_ips       = ["10.0.0.178"]
  security_groups   = []
  source_dest_check = false
}


# Interface for the bastion host (move out of the VPC definition to bastion definition)
resource "aws_network_interface" "eni-9a138b7b" {
  subnet_id         = "${aws_subnet.public.id}"
  private_ips       = ["10.0.0.184"]
  security_groups = ["${aws_security_group.bastion-host-inbound-from-internet.id}"]
  source_dest_check = true
  attachment {
    instance     = "i-04b8764a332f99f36"
    device_index = 0
  }
}


# eipalloc-9a5c6ea4
resource "aws_eip" "nat-gateway" {
  network_interface = "${aws_network_interface.nat-gateway.id}"
  vpc               = true
}


# nat-088dc4a463bf72e6e
resource "aws_nat_gateway" "private-to-internet" {
  allocation_id = "${aws_eip.nat-gateway.id}"
  subnet_id     = "${aws_subnet.public.id}"
}


# 
resource "aws_network_acl" "acl-dceb57ba" {
  vpc_id       = "${aws_vpc.main.id}"
  subnet_ids   = ["${aws_subnet.private.id}", "${aws_subnet.public.id}"]

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
