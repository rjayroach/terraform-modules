# modules/aws/ec2/bastion-host/main.tf

### Variables


variable "region" {}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "The name of the ssh key pair"
}

variable "access_cidr" {
  description = "The CIDR block for the Bastion Host"
  default     = "0.0.0.0/0"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "sg_bastion_id" {
  description = "The VPC id"
}

variable "subnet_public_id" {
  description = "public subnet id"
}

variable "subnet_az_public" {
  description = "public subnet az"
}

variable "component" {}
variable "environment" {}
variable "resource" {}
variable "service" {}

variable "vpc_security_group_ids" {}
variable "availability_zone" {}

### Outputs

output "instance_ips" {
  value = ["${aws_instance.bastion-host.*.private_ip}"]
}


### Implementation
/*
resource "aws_security_group" "bastion-host-inbound-from-internet" {
  name        = "bastion-host-inbound-from-internet"
  description = "Bastion host inbound from internet"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["${var.bastion_cidr}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
*/


resource "aws_security_group_rule" "allow_ssh_inbound" {
  type = "ingress"
  # security_group_id = "${aws_security_group.public.id}"
  security_group_id = "${var.sg_bastion_id}"

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${var.access_cidr}"]
}

/*
resource "aws_security_group" "bastion-host-internal-interface" {
  name        = "bastion-host-internal-interface"
  description = "public subnet to private subnet communications"
  vpc_id      = "${var.vpc_id}"

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
*/

# Debian Jessie
variable "debian-amis" {
  type    = "map"
  default = {
    us-east-1      = "ami-c8bda8a2"
    ap-southeast-1 = "ami-73974210"
    us-gov-west-1  = "ami-35b5d516"
  }
}

resource "aws_instance" "bastion-host" {
  # ami                         = "ami-29b38f3e"
  ami                         = "${lookup(var.debian-amis, var.region)}"
  # availability_zone           = "us-east-1d"
  availability_zone           = "${var.availability_zone}"
  ebs_optimized               = false
  instance_type               = "${var.instance_type}"
  monitoring                  = false
  key_name                    = "${var.key_name}"
  # subnet_id                   = "subnet-xxxxb629"
  subnet_id                   = "${var.subnet_public_id}"
  # vpc_security_group_ids      = ["sg-xxxx2a06"]
  vpc_security_group_ids      = ["${var.vpc_security_group_ids}"]
  associate_public_ip_address = true
  private_ip                  = "10.0.0.184"
  source_dest_check           = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  tags {
    Name        = "Set by the TF component (change me)"
    Component   = "${var.component}"
    Environment = "${var.environment}"
    Resource    = "${var.resource}"
    Service     = "${var.service}"
  }
}

# Interface for the bastion host (moved from the VPC definition to bastion definition)
resource "aws_network_interface" "bastion-host" {
  # subnet_id         = "${aws_subnet.public.id}"
  subnet_id         = "${var.subnet_public_id}"
  private_ips       = ["10.0.0.184"]
  # security_groups = ["${aws_security_group.bastion-host-inbound-from-internet.id}"]
  security_groups = ["${var.sg_bastion_id}"]
  source_dest_check = true
  attachment {
    # instance     = "i-04b8764a332f99f36"
    instance     = "${aws_instance.bastion-host.id}"
    device_index = 0
  }
}
