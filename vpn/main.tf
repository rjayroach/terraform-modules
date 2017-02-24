// variables

variable "vpc_id" { }

// outputs

// implementation

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_customer_gateway" "other_gateway" {
  bgp_asn = 65000
  ip_address = "172.0.0.1"
  type = "ipsec.1"
}

resource "aws_vpn_connection" "connection" {
  vpn_gateway_id = "${aws_vpn_gateway.vpn_gateway.id}"
  customer_gateway_id = "${aws_customer_gateway.other_gateway.id}"
  type = "ipsec.1"
  static_routes_only = true
}
