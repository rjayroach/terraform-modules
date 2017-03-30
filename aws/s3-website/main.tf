# modules/aws/s3-website/main.tf
# Params:
# - S3 Policy Bucket JSON file
# Creates:
# - An IAM user to deploy the application
# - An IAM Policy Document with permissions to allow the IAM user to write to the S3 Bucket
# - An S3 Bucket to deploy the application into
# - An ENV file with the bucket name, region and the IAM User Credentials (used by Ember to deploy the app)


### Variables
variable "region" {}

variable "allowed_ip" {
  description = "The IP address that may access the bucket"
}

variable "application" {
  description = "The name of the application (becomes the IAM User name)"
}

variable "bucket_name" {
  description = "The name of the S3 bucket to which the application will be deployed"
}

variable "credentials_file" {
  description = "The file name to write the bucket details and credentials"
}

variable "environment" {
  description = "The environment to which the resources belong"
}

variable "api_url" {
  description = "The remote url that serves the application's backend API"
}

variable "iam_user_name" {
  description = "The name of the IAM user to be created to administrate the S3 bucket"
}


### Outputs

output "dns_name" {
  value = "${aws_s3_bucket.app.website_domain}"
}

output "zone_id" {
  value = "${aws_s3_bucket.app.hosted_zone_id}"
}


### Implementation

# Create an IAM user to deploy the application to S3
resource "aws_iam_user" "app" {
  name = "${var.iam_user_name}"
}


# Create the IAM API credentials
resource "aws_iam_access_key" "app" {
  user = "${aws_iam_user.app.name}"
}


# Create a policy for the bucket
data "aws_iam_policy_document" "app" {
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
      type        = "AWS"
      identifiers = ["${aws_iam_user.app.arn}"]
    }
  }

#   statement {
#     effect    = "Deny"
#     sid       = "IPDeny"
#     actions   = [
#       "s3:*",
#     ]
#     resources = [
#       "arn:aws:s3:::${var.bucket_name}/*",
#     ]
#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }
#     condition = {
#       test     = "IpAddress"
#       variable = "aws:SourceIp"
#       values   = [
#         "0.0.0.0/0"
#       ]
#     }
#     condition = {
#       test     = "NotIpAddress"
#       variable = "aws:SourceIp"
#       values   = [
#         "${var.allowed_ip}"
#       ]
#     }
#   }
}


# Create a bucket for the Application
resource "aws_s3_bucket" "app" {
  bucket        = "${var.bucket_name}"
  policy        = "${data.aws_iam_policy_document.app.json}"
  region        = "${var.region}"
  acl           = "public-read"
  force_destroy = true
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}


# Create an ENV file used be ember-cli-deploy
data "template_file" "envs" {
  template = "${file("${path.module}/templates/bucket_env")}"
  depends_on = ["aws_s3_bucket.app"]
  vars {
    aws_bucket            = "${var.bucket_name}"
    aws_region            = "${var.region}"
    aws_access_key_id     = "${aws_iam_access_key.app.id}"
    aws_secret_access_key = "${aws_iam_access_key.app.secret}"
    api_url               = "${var.api_url}"
  }
}

resource "null_resource" "envs" {
  triggers {
    # template_rendered = "${data.template_file.envs.rendered}"
    env_file = "${sha1(file("${var.credentials_file}"))}"
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.envs.rendered}' > ${var.credentials_file}"
  }
}
