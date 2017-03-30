# modules/aws/rds/main.tf

### Variables

variable "identifier" {}
variable "allocated_storage" {}
variable "storage_type" {}
variable "engine" {}
variable "engine_version" {}
variable "instance_class" {}
variable "name" {}
variable "username" {}
variable "password" {}
variable "port" {}
variable "publicly_accessible" {}
variable "availability_zone" {}
variable "vpc_security_group_ids" {}
variable "vpc_subnet_ids" { type = "list" }
# variable "db_subnet_group_name" {}
variable "parameter_group_name" {}
variable "multi_az" {}
variable "backup_retention_period" {}
variable "final_snapshot_identifier" {}
variable "storage_encrypted" {}

variable "env_file" {
  description = "The file name to write the endpoint hostname to"
}

variable "vpc_id" {}
variable "cidr_blocks" { type = "list" }


# ### Outputs
# output "instance_id" {
#   value = "${aws_db_instance.main.id}"
# }
# 
# output "instance_address" {
#   value = "${aws_db_instance.main.address}"
# }


### Implementation

resource "aws_db_subnet_group" "main" {
  name = "${var.identifier}-group"
  description = "RDS subnet group"
  subnet_ids = ["${var.vpc_subnet_ids}"]
}

resource "aws_security_group" "main" {
  name = "${var.identifier}-sg"
  description = "RDS Security Group"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "allow_5432_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.main.id}"

  from_port   = 0
  to_port     = 5432
  protocol    = "TCP"
  cidr_blocks = ["${var.cidr_blocks}"]
}

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }


resource "aws_db_instance" "main" {
  identifier                = "${var.identifier}"
  allocated_storage         = "${var.allocated_storage}"
  storage_type              = "${var.storage_type}"
  engine                    = "${var.engine}"
  engine_version            = "${var.engine_version}"
  instance_class            = "${var.instance_class}"
  name                      = "${var.name}"
  username                  = "${var.username}"
  password                  = "${var.password}"
  port                      = "${var.port}"
  publicly_accessible       = "${var.publicly_accessible}"
  availability_zone         = "${var.availability_zone}"
  # vpc_security_group_ids    = ["${var.vpc_security_group_ids}"]
  vpc_security_group_ids    = ["${aws_security_group.main.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.main.name}"
  parameter_group_name      = "${var.parameter_group_name}"
  multi_az                  = "${var.multi_az}"
  backup_retention_period   = "${var.backup_retention_period}"
  # backup_window             = "16:35-17:05"
  # maintenance_window        = "mon:21:27-mon:21:57"
  final_snapshot_identifier = "${var.final_snapshot_identifier}"
  # count = 1
  count = "${var.identifier == "" ? 0 : 1}"
  storage_encrypted = "${var.storage_encrypted}"
  # kms_key_id
}


# Create an ENV file used be ember-cli-deploy
data "template_file" "envs" {
  template = "${file("${path.module}/templates/env")}"
  depends_on = ["aws_db_instance.main"]
  vars {
    db_instance_address = "${aws_db_instance.main.address}"
  }
}

resource "null_resource" "envs" {
  triggers {
    env_file = "${sha1(file("${var.env_file}"))}"
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.envs.rendered}' > ${var.env_file}"
  }
}
