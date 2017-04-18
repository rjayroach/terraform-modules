# modules/aws/app-server-with-elb/main.tf
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



### Variables

variable "key_name" {
  description = "The name of the ssh key pair"
}

variable "application" {
  default = "Set by the TF component (change me)"
  description = "The application to which the resources belong"
}

variable "component" {
  default = "Set by the TF component (change me)"
  description = "The environment to which the resources belong"
}

variable "environment" {
  default = "Set by the TF component (change me)"
  description = "The environment to which the resources belong"
}

variable "resource" {
  default = "Set by the TF component (change me)"
  description = "The resource to which the resources belong"
}

variable "service" {
  default = "Set by the TF component (change me)"
  description = "The environment to which the resources belong"
}

variable "instance_type" { description = "The instance type of the server" }
variable "server_cert_arn" { description = "The arn of the server certificate to install on the ELB" }
variable "subnet_id" { description = "The ID of the VPC subnet" }
variable "vpc_id" {}
variable "vpc_security_group_ids" { description = "The security group ids" }
variable "region" {}
variable "security_group_elb_id" {}

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
    us-gov-west-1  = "ami-35b5d516"
  }
}


### Outputs

output "dns_name" {
  value = "${aws_elb.app.dns_name}"
}

output "instance_id" {
  value = "${aws_instance.app.instance_id}"
}

output "zone_id" {
  value = "${aws_elb.app.zone_id}"
}


### Implementation

# NOTE: the security group ids can maybe come directly from this template
resource "aws_instance" "app" {
  ami                    = "${lookup(var.debian-amis, var.region)}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  subnet_id              = "${var.subnet_id}"
  tags {
    Name        = "Set by the TF component (change me)"
    Component   = "${var.component}"
    Environment = "${var.environment}"
    Resource    = "${var.resource}"
    Service     = "${var.service}"
  }
}



resource "aws_elb" "app" {
  name                      = "${var.application}-elb"
  # security_groups           = ["${aws_security_group.elb.id}"]
  security_groups           = ["${var.security_group_elb_id}"]
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
