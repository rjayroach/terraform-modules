// variables

variable "aws_region" {}

variable "ec2_instance_type" { default = "t2.micro" }

variable "user" {}

variable "vpc_id" {}

// outputs

output "public_ip" {
  value = "${aws_instance.ec2.public_ip}"
}

// implementation

resource "aws_instance" "ec2" {
  ami = "ami-f824809b"
  instance_type = "${var.ec2_instance_type}"
  vpc_security_group_ids = [
    "${module.global-allow.group_id}"
  ]

  tags {
    OS   = "Ubuntu"
    User = "${var.user}"
  }
}

module "global-allow" {
  source = "../sec-groups"

  vpc_id =
}
