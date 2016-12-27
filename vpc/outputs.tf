# modules/vpc/outputs.tf

output "elb_id" {
  value = "${aws_elb.example.id}"
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}

output "elb_zone_id" {
  value = "${aws_elb.example.zone_id}"
}

output "vpc_security_group_ids" {
  # value = ["${aws_security_group.appserver.id}"]
  value = "${aws_security_group.appserver.id}"
}

output "subnet_id" {
  value = "${aws_subnet.public.id}"
}
