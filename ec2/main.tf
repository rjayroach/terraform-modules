// variables

variable "amis" {}

variable "region" {}

variable "ec2_instance_type" { default = "t2.micro" }

variable "environment" { default = "development" }

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
  vpc_security_group_ids = [
    "${module.global-allow.group_id}"
  ]

  tags {
    User = "${var.user}"
  }
}

module "global-allow" {
  source = "../sec-groups"

  environment = "${var.environment}"
  vpc_id = "${var.vpc_id}"
}
