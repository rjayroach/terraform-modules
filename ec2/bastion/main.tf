// variables

variable "environment" { default = "development" }

variable "vpc_id" {}

// outputs

output "public_ip" {
  value = "${aws_instance.ec2.public_ip}"
}

// implementation

resource "aws_instance" "bastion" {
  ami = "ami-f824809b"
  instance_type = "${var.ec2_instance_type}"
  vpc_security_group_ids = [
    "${module.global-allow.group_id}"
  ]

  tags {
    User = "${var.user}"
  }
}
module "aws_instance" {
  source = "../"

  environment = "${var.environment}"
  publicly_available = true
}
