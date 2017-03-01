# modules/vpc/outputs.tf

output "vpc_security_group_ids" {
  # value = ["${aws_security_group.appserver.id}"]
  value = "${aws_security_group.public.id}"
}

output "subnet_id" {
  value = "${aws_subnet.public.id}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}
