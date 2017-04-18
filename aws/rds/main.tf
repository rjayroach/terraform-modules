# modules/aws/rds/main.tf

### Variables

variable "ansible_vars_file" {
  description = "The full path to the file which to write the endpoint to"
}
variable "ansible_vars_key" {
  description = "The key under which to write the endpoint"
}
variable "allocated_storage" {}
variable "availability_zone" {}
variable "backup_retention_period" {}
variable "backup_window" {}
variable "cidr_blocks" {}
  # type = "list"
  # default = ["172.16.0.0/24", "172.16.1.0/24"]
# }
variable "engine" {}
variable "engine_version" {}
variable "final_snapshot_identifier" {}
variable "identifier" {}
variable "instance_class" {}
variable "maintenance_window" {}
variable "multi_az" {}
variable "name" {}
variable "parameter_group_name" {}
variable "password" {}
variable "port" {}
variable "publicly_accessible" {}
variable "storage_encrypted" {}
variable "storage_type" {}
variable "username" {}
variable "vpc_id" {}
variable "vpc_security_group_ids" {}
variable "vpc_subnet_ids" { type = "list" }


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
  security_group_id = "${aws_security_group.main.id}"
  type              = "ingress"
  from_port         = 0
  to_port           = 5432
  protocol          = "TCP"
  cidr_blocks       = ["${var.cidr_blocks}"]
}

# resource "aws_security_group_rule" "idallow_5432_inbound" {
#   security_group_id = "${aws_security_group.main.id}"
#   type              = "egress"
# 
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
# }


resource "aws_db_instance" "main" {
  allocated_storage         = "${var.allocated_storage}"
  availability_zone         = "${var.availability_zone}"
  backup_window             = "${var.backup_window}"
  backup_retention_period   = "${var.backup_retention_period}"
  count = 1
  db_subnet_group_name      = "${aws_db_subnet_group.main.name}"
  engine                    = "${var.engine}"
  engine_version            = "${var.engine_version}"
  final_snapshot_identifier = "${var.final_snapshot_identifier}"
  identifier                = "${var.identifier}"
  instance_class            = "${var.instance_class}"
  maintenance_window        = "${var.maintenance_window}"
  multi_az                  = "${var.multi_az}"
  name                      = "${var.name}"
  password                  = "${var.password}"
  parameter_group_name      = "${var.parameter_group_name}"
  port                      = "${var.port}"
  publicly_accessible       = "${var.publicly_accessible}"
  storage_encrypted         = "${var.storage_encrypted}"
  storage_type              = "${var.storage_type}"
  username                  = "${var.username}"
  # vpc_security_group_ids    = ["${var.vpc_security_group_ids}"]
  vpc_security_group_ids    = ["${aws_security_group.main.id}"]
  # kms_key_id
}


# Create an ENV file used be ember-cli-deploy
data "template_file" "envs" {
  template = "${file("${path.module}/templates/env")}"
  depends_on = ["aws_db_instance.main"]
  vars {
    db_instance_address = "${aws_db_instance.main.address}"
    ansible_vars_key    = "${var.ansible_vars_key}"
  }
}

resource "null_resource" "envs" {
  triggers {
    env_file = "${sha1(file("${var.ansible_vars_file}"))}"
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.envs.rendered}' > ${var.ansible_vars_file}"
  }
}
