// variables

variable "region" { }

variable "lambda_payload_url" { default = "hello-world-python.zip" }

variable "lambda_runtime"     { default = "python2.7"}

variable "lambda_memory"      { default = "128"}

// outputs

// implementation

data "aws_iam_policy_document" "lambda" {
  statement = {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals = {
      type = "service"
      identifiers = [ "lambda.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_lambda_function" "lambda" {
  filename = "${var.lambda_payload_url}"
  function_name = "lambda_function_name"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "exports.test"
  source_code_hash = "${base64sha256(file("${var.lambda_payload_url}"))}"
  runtime = "${var.lambda_runtime}"
  memory_size = "${var.lambda_memory}"
}
