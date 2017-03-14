// variables

variable "ec2_instance_type" { "t2.micro" }

variable "environment" { default = "development" }

variable "region" {}

variable "vpc_id" {}

// outputs

output "public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

// implementation

resource "aws_instance" "bastion" {
  ami = "ami-f824809b"
  instance_type = "${var.ec2_instance_type}"
  vpc_security_group_ids = [
    "${module.global-allow.group_id}"
  ]
  publicly_available = true

  tags {
    Environment = "${var.environment}"
    User = "${var.user}"
  }
}
