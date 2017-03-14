// variables

variable "bucket_name" {}

variable "environment" {}

variable "region" {}

variable "versioning" { default = false }


// outputs

output "name" { value = "${var.bucket_name}" }


// implementation

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}"
  acl = "private"

  versioning {
    enabled = "${var.versioning}"
  }

  tags {
    Name        = "${var.bucket_name}"
    Environment = "${var.environment}"
  }
}
