# modules/vpc/outputs.tf

# Needed for the service instances to attach to the ELB
output "elb_id" {
  value = "${aws_elb.main.id}"
}

output "vpc_security_group_ids" {
  # value = ["${aws_security_group.appserver.id}"]
  value = "${aws_security_group.appserver.id}"
}

output "subnet_id" {
  value = "${aws_subnet.public.id}"
}

output "subdomain_zone_id" {
  value = "${aws_route53_zone.subdomain.zone_id}"
}
