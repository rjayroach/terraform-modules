# modules/s3-website/main.tf
# Params:
# - S3 Policy Bucket JSON file
# Creates:
# - An IAM user to deploy the application
# - An IAM Policy Document with permissions to allow the IAM user to write to the S3 Bucket
# - An S3 Bucket to deploy the application into
# - A DNS Record mapped to the S3 Bucket
# - An ENV file with the bucket name, region and the IAM User Credentials (used by Ember to deploy the app)


# Create an IAM user to deploy the application to S3
resource "aws_iam_user" "app" {
  name = "${var.application}-${var.environment}"
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

# Create a DNS Record for the bucket
resource "aws_route53_record" "app" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.bucket_name}"
  type    = "A"
  alias {
    name                   = "${aws_s3_bucket.app.website_domain}"
    zone_id                = "${aws_s3_bucket.app.hosted_zone_id}"
    evaluate_target_health = true
  }
}


# Create an ENV file used be ember-cli-deploy
data "template_file" "envs" {
  template = "${file("${path.module}/templates/bucket_env")}"
  depends_on = ["aws_s3_bucket.app"]
  vars {
    aws_bucket            = "${var.bucket_name}"
    aws_region            = "${var.region}"
    aws_access_key_id_x     = "${aws_iam_access_key.app.id}"
    aws_secret_access_key_x = "${aws_iam_access_key.app.secret}"
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
