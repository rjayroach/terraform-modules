# modules/app-server-with-elb/main.tf
# Creates:
# - An EC2 instance onto which to deploy the application
# - A keypair to assign to the EC2 for configuration by Ansible and ssh access
# - An ELB to handle SSL and forwrard the requests
# - Attach the EC2 to the ELB
# - DNS Record(s) mapped to the ELB

# TODO: Get the details for Debian
# data "aws_ami" "debian" {
#   most_recent = true
#   filter {
#     name = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
#   }
#   filter {
#     name = "virtualization-type"
#     values = ["hvm"]
#   }
#   owners = ["099720109477"] # Canonical
# }


# Kubernetes on Debian 8.6
variable "k8s-amis" {
  type    = "map"
  default = {
    ap-southeast-1 = "ami-c12d8ba2"
  }
}


# Debian Jessie
variable "debian-amis" {
  type    = "map"
  default = {
    us-east-1      = "ami-c8bda8a2"
    ap-southeast-1 = "ami-73974210"
  }
}

resource "aws_key_pair" "ansible" {
  key_name   = "ansible-${var.application}"
  public_key = "${file("${var.public_key}")}"
}

# NOTE: the security group ids can maybe come directly from this template
resource "aws_instance" "app" {
  ami                    = "${lookup(var.debian-amis, var.region)}"
  instance_type          = "${var.instance_type}"
  key_name               = "ansible-${var.application}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  subnet_id              = "${var.subnet_id}"
  tags {
    Environment = "${var.environment}"
    Name        = "master-1"
    Role        = "master"
  }
}

# resource "aws_instance" "worker" {
#   count                  = "2"
#   ami                    = "${lookup(var.debian-amis, var.region)}"
#   instance_type          = "${var.instance_type}"
#   key_name               = "ansible-${var.environment}"
#   vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
#   subnet_id              = "${var.subnet_id}"
#   tags {
#     Environment = "${var.environment}"
#     Name        = "worker-${count.index}"
#     Role        = "worker"
#   }
# }



# TODO: the public subnet ID probably needs to come from a var (from VPC)
resource "aws_elb" "app" {
  name                      = "${var.application}-elb"
  security_groups           = ["${aws_security_group.elb.id}"]
  subnets                   = ["${var.subnet_id}"]
  cross_zone_load_balancing = true

  listener {
    instance_port      = 3000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.server_cert_arn}"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    # target            = "HTTP:8000/"
    target              = "TCP:3000"
    interval            = 30
  }

  tags {
    Application = "${var.application}"
    Environment = "${var.environment}"
    Name        = "appserver"
  }
}

# Create a new load balancer attachment
resource "aws_elb_attachment" "app" {
  elb      = "${aws_elb.app.id}"
  instance = "${aws_instance.app.id}"
}


# Create an ALIAS record for the API server pointing to the ELB
# TODO: The subdomain zone_id needs to come from a var
# TODO: see about passing in multiple hostnames in the var
# resource "aws_route53_record" "elb" {
#   zone_id = "${var.route53_zone_id}"
#   name    = "${var.route53_hostname}"
#   type    = "A"
#   alias {
#     name                   = "${aws_elb.app.dns_name}"
#     zone_id                = "${aws_elb.app.zone_id}"
#     evaluate_target_health = true
#   }
# }

# Create an Alternative ALIAS record for the API server pointing to the ELB
resource "aws_route53_record" "elb-alt" {
  zone_id = "${var.route53_primary_zone_id}"
  name    = "${var.route53_hostname}"
  type    = "A"
  alias {
    name                   = "${aws_elb.app.dns_name}"
    zone_id                = "${aws_elb.app.zone_id}"
    evaluate_target_health = true
  }
}


# port 3000 from ELB
resource "aws_security_group_rule" "allow_3000_inbound" {
  type = "ingress"
  # security_group_id = "${aws_security_group.appserver.id}"
  security_group_id = "${var.vpc_security_group_ids}"

  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  # TODO: only accept traffic from the ELB
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  # security_group_id = "${aws_security_group.public.id}"
  security_group_id = "${var.vpc_security_group_ids}"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group" "elb" {
  name        = "appserver-elb"
  description = "ELB Security Group"
  # vpc_id      = "${aws_vpc.main.id}"
  vpc_id      = "${var.vpc_id}"
  tags {
    Environment = "${var.environment}"
    Name        = "elb-${var.application}"
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
