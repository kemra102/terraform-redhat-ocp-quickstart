resource "aws_autoscaling_group" "ocp_master" {
  name                 = "ocp-master-asg-${random_id.suffix.hex}"
  vpc_zone_identifier  = ["${aws_subnet.openshift_private.*.id}"]
  desired_capacity     = "3"
  min_size             = "2"
  max_size             = "3"
  launch_configuration = "${aws_launch_configuration.ocp_master.name}"
  tags                 = ["${var.default_asg_tags}"]

  tags = [
    {
      key                 = "Name"
      value               = "ocp-master-asg-${random_id.suffix.hex}"
      propagate_at_launch = true
    },
  ]
}

resource "aws_elb" "ocp_master_external" {
  count = "${var.enable_external_master_elb}"

  name                      = "ocp-master-external-${random_id.suffix.hex}"
  cross_zone_load_balancing = true
  subnets                   = ["${aws_subnet.openshift_public.*.id}"]
  idle_timeout              = 1200
  listener                  = ["${var.ocp_master_external_elb_listeners}"]
  tags                      = "${merge(var.default_tags, map("Name", "ocp-master-external-${random_id.suffix.hex}"))}"

  security_groups = [
    "${aws_security_group.ocp_internal.id}",
    "${aws_security_group.ocp_master_external.id}",
  ]

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    target              = "TCP:22"
    interval            = 30
    timeout             = 3
  }
}

resource "aws_autoscaling_attachment" "ocp_master_external" {
  count = "${var.enable_external_master_elb}"

  autoscaling_group_name = "${aws_autoscaling_group.ocp_master.name}"
  elb                    = "${aws_elb.ocp_master_external.name}"
}

resource "aws_elb" "ocp_master_internal" {
  name                      = "ocp-master-internal-${random_id.suffix.hex}"
  cross_zone_load_balancing = true
  subnets                   = ["${aws_subnet.openshift_private.*.id}"]
  security_groups           = ["${aws_security_group.ocp_internal.id}"]
  idle_timeout              = 1200
  internal                  = true
  listener                  = ["${var.ocp_master_internal_elb_listeners}"]
  tags                      = "${merge(var.default_tags, map("Name", "ocp-master-internal-${random_id.suffix.hex}"))}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    target              = "TCP:22"
    interval            = 30
    timeout             = 3
  }
}

resource "aws_autoscaling_attachment" "ocp_master_internal" {
  autoscaling_group_name = "${aws_autoscaling_group.ocp_master.name}"
  elb                    = "${aws_elb.ocp_master_internal.name}"
}

resource "aws_launch_configuration" "ocp_master" {
  name                 = "ocp-master-lc-${random_id.suffix.hex}"
  image_id             = "${data.aws_ami.rhel74.id}"
  instance_type        = "${var.master_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.setup_role_profile.id}"
  key_name             = "${var.keypair_name}"
  enable_monitoring    = true
  user_data            = "${data.template_cloudinit_config.ocp_master.rendered}"

  security_groups = [
    "${aws_security_group.ocp_instances.id}",
    "${aws_security_group.ocp_internal.id}",
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.master_root_block_device_size}"
  }
}

data "template_cloudinit_config" "ocp_master" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.common_user_data.rendered}"
  }
}
