// variables

variable "environment" { }

variable "vpc_id" { }

// outputs

output "group_id"   { value = "${aws_security_group.global-allow.id}" }

output "group_name" { value = "${aws_security_group.global-allow.name}" }

output "vpc_security_group_ids" {
  value = [ "${aws_security_group.global-allow.group_id}" ]
}

// implementation

resource "aws_security_group" "global-allow" {
  name = "global-allow-ping-and-ssh"

  vpc_id = "${var.vpc_id}"

  tags {
    Visibility = "public"
    Name       = "${var.environment}-public"
  }
}

resource "aws_security_group_rule" "allow-ping" {
  security_group_id = "${aws_security_group.global-allow.id}"

  type = "ingress"
  from_port   = 8
  to_port     = 0
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow-ssh" {
  security_group_id = "${aws_security_group.global-allow.id}"

  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
