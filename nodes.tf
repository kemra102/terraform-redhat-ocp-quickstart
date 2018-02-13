resource "aws_autoscaling_group" "ocp_node" {
  name                 = "ocp-node-asg-${random_id.suffix.hex}"
  vpc_zone_identifier  = ["${aws_subnet.openshift_private.*.id}"]
  desired_capacity     = "${var.number_of_nodes}"
  min_size             = "2"
  max_size             = "${var.number_of_nodes}"
  launch_configuration = "${aws_launch_configuration.ocp_node.name}"
  tags                 = ["${var.default_asg_tags}"]

  tags = [
    {
      key                 = "Name"
      value               = "ocp-node-asg-${random_id.suffix.hex}"
      propagate_at_launch = true
    },
  ]

  depends_on = ["aws_autoscaling_group.ocp_master"]
}

resource "aws_elb" "ocp_node_external" {
  count = "${var.enable_external_node_elb}"

  name                      = "ocp-node-external-${random_id.suffix.hex}"
  cross_zone_load_balancing = true
  subnets                   = ["${aws_subnet.openshift_public.*.id}"]
  idle_timeout              = 1200
  listener                  = ["${var.ocp_node_external_elb_listeners}"]
  tags                      = "${merge(var.default_tags, map("Name", "ocp-node-external-${random_id.suffix.hex}"))}"

  security_groups = [
    "${aws_security_group.ocp_internal.id}",
    "${aws_security_group.ocp_node_external.id}",
  ]

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    target              = "TCP:22"
    interval            = 30
    timeout             = 3
  }
}

resource "aws_autoscaling_attachment" "ocp_node_external" {
  count = "${var.enable_external_node_elb}"

  autoscaling_group_name = "${aws_autoscaling_group.ocp_node.name}"
  elb                    = "${aws_elb.ocp_node_external.name}"
}

resource "aws_elb" "ocp_node_internal" {
  name                      = "ocp-node-internal-${random_id.suffix.hex}"
  cross_zone_load_balancing = true
  subnets                   = ["${aws_subnet.openshift_private.*.id}"]
  security_groups           = ["${aws_security_group.ocp_internal.id}"]
  internal                  = true
  listener                  = ["${var.ocp_node_internal_elb_listeners}"]
  tags                      = "${merge(var.default_tags, map("Name", "ocp-node-internal-${random_id.suffix.hex}"))}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    target              = "TCP:22"
    interval            = 30
    timeout             = 3
  }
}

resource "aws_autoscaling_attachment" "ocp_node_internal" {
  autoscaling_group_name = "${aws_autoscaling_group.ocp_node.name}"
  elb                    = "${aws_elb.ocp_node_internal.name}"
}

resource "aws_launch_configuration" "ocp_node" {
  name                 = "ocp-node-lc-${random_id.suffix.hex}"
  image_id             = "${data.aws_ami.rhel74.id}"
  instance_type        = "${var.node_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.setup_role_profile.id}"
  key_name             = "${var.keypair_name}"
  enable_monitoring    = true
  user_data            = "${data.template_cloudinit_config.ocp_node.rendered}"

  security_groups = [
    "${aws_security_group.ocp_instances.id}",
    "${aws_security_group.ocp_internal.id}",
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.node_root_block_device_size}"
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = "${var.node_data_block_device_size}"
  }
}

data "template_cloudinit_config" "ocp_node" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.common_user_data.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.node_user_data.rendered}"
  }
}

data "template_file" "node_user_data" {
  template = "${file("${path.module}/templates/node_user_data.sh")}"
}
