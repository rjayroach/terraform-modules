# modules/services/main.tf

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

# Debian Jessie
variable "amis" {
  type    = "map"
  default = {
    us-east-1      = "ami-c8bda8a2"
    ap-southeast-1 = "ami-73974210"
  }
}

resource "aws_key_pair" "ansible" {
  key_name   = "ansible-${var.environment}"
  public_key = "${var.public_key}"
}

resource "aws_instance" "manager" {
  ami                    = "${lookup(var.amis, var.region)}"
  instance_type          = "${var.instance_type}"
  key_name               = "ansible-${var.environment}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  subnet_id              = "${var.subnet_id}"
  tags {
    Environment = "${var.environment}"
    Name        = "manager-1"
    Role        = "manager"
  }
}

# resource "aws_instance" "worker" {
#   count                  = "2"
#   ami                    = "${lookup(var.amis, var.region)}"
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

# Create a new load balancer attachment
resource "aws_elb_attachment" "manager" {
  elb      = "${var.elb_id}"
  instance = "${aws_instance.manager.id}"
}

# Create a bucket for the Application
resource "aws_s3_bucket" "app-bucket" {
  bucket = "${var.bucket_name}"
  policy = "${var.bucket_policy}"
  region = "${var.region}"
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
}
