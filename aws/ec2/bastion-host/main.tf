# modules/aws/ec2/bastion-host/main.tf

### Variables

variable "bastion_cidr" {
  description = "The CIDR block for the Bastion Host"
  default     = "0.0.0.0/0"
}


### Outputs

output "instance_ips" {
  value = ["${aws_instance.default-api-server.*.private_ip}"]
}


### Implementation

resource "aws_security_group" "vpc-xxxxxxxx-bastion-host-inbound-from-internet" {
  name        = "bastion-host-inbound-from-internet"
  description = "Bastion host inbound from internet"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = "${var.bastion_cidr}"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "vpc-xxxxxxxx-bastion-host-internal-interface" {
  name        = "bastion-host-internal-interface"
  description = "public subnet to private subnet communications"
  vpc_id      = "${module.vpc.vpc_id}"

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


resource "aws_instance" "bastion-host" {
  ami                         = "ami-29b38f3e"
  availability_zone           = "us-east-1d"
  ebs_optimized               = false
  instance_type               = "t2.micro"
  monitoring                  = false
  key_name                    = "xxxible"
  subnet_id                   = "subnet-xxxxb629"
  vpc_security_group_ids      = ["sg-xxxx2a06"]
  associate_public_ip_address = true
  private_ip                  = "10.0.0.184"
  source_dest_check           = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  tags {
    "Environment" = "production"
    "Application" = "default"
    "Name" = "bastion-host"
  }
}
