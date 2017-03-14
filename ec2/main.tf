// variables

variable "amis" { type = "map" }

variable "region" {}

variable "ec2_instance_count" { }

variable "ec2_instance_type" { }

variable "environment" { }

variable "security_groups" { type = "list" }

variable "subnet_id" { }

variable "user" {}

variable "vpc_id" {}


// outputs

output "public_ip" {
  value = "${aws_instance.ec2.public_ip}"
}


// implementation

resource "aws_instance" "ec2" {
  ami = "${lookup(var.amis, "${var.region}", "")}"
  instance_type = "${var.ec2_instance_type}"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = [ "${var.security_groups}" ]

  tags {
    User = "${var.user}"
  }
}
