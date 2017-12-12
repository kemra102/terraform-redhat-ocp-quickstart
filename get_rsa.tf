resource "aws_cloudformation_stack" "get_rsa" {
  name          = "get-rsa"
  on_failure    = "ROLLBACK"
  template_body = "${file("${path.module}/templates/get_rsa.template")}"

  parameters {
    GenRSALambdaArn = "${aws_lambda_function.key_gen.arn}"
  }
}
