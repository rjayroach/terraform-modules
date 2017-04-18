# modules/sg/app-server-with-elb/main.tf

### Variables

variable "vpc_id" {}
variable "tag_name" {}
variable "vpc_security_group_ids" { description = "The security group ids" }


### Outputs

output "security_group_elb_id" {
  value = "${aws_security_group.elb.id}"
}


### Implementation

# port 3000 from ELB
resource "aws_security_group_rule" "allow_3000_inbound" {
  type = "ingress"
  security_group_id = "${var.vpc_security_group_ids}"

  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  # TODO: only accept traffic from the ELB
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = "${var.vpc_security_group_ids}"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group" "elb" {
  name        = "appserver-elb"
  description = "ELB Security Group"
  vpc_id      = "${var.vpc_id}"
  tags {
    Name        = "${var.tag_name}"
  }
}

resource "aws_security_group_rule" "elb_allow_https_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "elb_allow_all_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.elb.id}"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
