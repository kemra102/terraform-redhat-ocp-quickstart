resource "aws_lambda_function" "key_gen" {
  s3_bucket     = "${var.qs_s3_bucket_name}-lambda-${data.aws_region.current.name}"
  s3_key        = "generate_sshkeys/genrsa_lambda.zip"
  function_name = "key-gen"
  handler       = "service.handler"
  runtime       = "python2.7"
  timeout       = "5"
  role          = "${aws_iam_role.lambda_execution_role.arn}"
  tags          = "${merge(var.default_tags, map("Name", "key-gen"))}"
}
