// variables

variable "adsync_password" {}

variable "domain" {}

variable "domain_prefix" { default = "corp" }

variable "size" { default = "Small" }

variable "subnet_ids" { type = "list" }

variable "vpc_id" {}

// outputs

// implementation

resource "aws_directory_service_directory" "adsync" {
  name = "${var.domain_prefix}.${var.domain}"
  password = "${var.adsync_password}"
  size = "${var.size}"
  enable_sso = true

  vpc_settings {
    vpc_id = "${var.vpc_id}"
    subnet_ids = [
      "${var.subnet_ids}"
    ]
  }
}
