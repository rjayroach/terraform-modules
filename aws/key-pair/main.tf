### Variables

variable "key_name" {
  description = "The name of the ssh key pair"
}

variable "public_key_path" {
  description = "The path to the public key"
}

### Implementation
resource "aws_key_pair" "main" {
  key_name   = "${var.key_name}"
  public_key = "${file("${var.public_key_path}")}"
}
