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
    Name        = "master-1"
    Role        = "master"
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



##### S3 Bucket to Host Application
# Create a policy for the bucket
data "aws_iam_policy_document" "app_bucket" {
  statement {
    effect    = "Allow"
    sid       = "Stmt1EmberCLIS3DeployPolicy"
    actions   = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectACL",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
    principals {
      type = "AWS"
      identifiers = ["${var.bucket_iam_user_arn}"]
    }
  }
}

# Create a bucket for the Application
resource "aws_s3_bucket" "app-bucket" {
  bucket        = "${var.bucket_name}"
  policy        = "${data.aws_iam_policy_document.app_bucket.json}"
  region        = "${var.region}"
  acl           = "public-read"
  force_destroy = true
  website {
    index_document = "index.html"
  }
  provisioner "local-exec" {
    command = "echo \"  AWS_BUCKET_${var.environment}: ${var.bucket_name}\n  AWS_REGION_${var.environment}: ${var.region}\" > /tmp/s3_bucket_${var.environment}.yml"
  }
}

# Create a DNS Record for the bucket
resource "aws_route53_record" "app-bucket" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.bucket_name}"
  type    = "A"
  alias {
    name                   = "${aws_s3_bucket.app-bucket.website_domain}"
    zone_id                = "${aws_s3_bucket.app-bucket.hosted_zone_id}"
    evaluate_target_health = true
  }
}
