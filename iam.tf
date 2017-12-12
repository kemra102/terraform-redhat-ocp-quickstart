resource "aws_iam_role" "lambda_execution_role" {
  name_prefix        = "lambda-execution-role-"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_execution_role.json}"
}

data "aws_iam_policy_document" "lambda_execution_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name_prefix = "lambda-policy-"
  role        = "${aws_iam_role.lambda_execution_role.id}"
  policy      = "${data.aws_iam_policy_document.lambda_policy.json}"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["cloudformation:DescribeStacks"]
  }
}

resource "aws_iam_instance_profile" "setup_role_profile" {
  name_prefix = "setup-role-profile-"
  role        = "${aws_iam_role.setup_role.name}"
}

resource "aws_iam_role" "setup_role" {
  name_prefix        = "setup-role-"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.assume_setup_role.json}"
}

data "aws_iam_policy_document" "assume_setup_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "setup_role" {
  name_prefix = "setup-role-"
  role        = "${aws_iam_role.setup_role.id}"
  policy      = "${data.aws_iam_policy_document.setup_role.json}"
}

data "aws_iam_policy_document" "setup_role" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.qs_s3_bucket_name}/${var.qs_s3_key_prefix}*"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:Describe*",
      "autoscaling:AttachLoadBalancers",
      "ec2:Describe*",
    ]
  }
}
