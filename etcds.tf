resource "aws_autoscaling_group" "ocp_etcd" {
  name                 = "ocp-etcd-${random_id.suffix.hex}"
  vpc_zone_identifier  = ["${aws_subnet.openshift_private.*.id}"]
  desired_capacity     = "3"
  min_size             = "2"
  max_size             = "3"
  launch_configuration = "${aws_launch_configuration.ocp_etcd.name}"
  tags                 = ["${var.default_asg_tags}"]

  tags = [
    {
      key                 = "Name"
      value               = "ocp-etcd-${random_id.suffix.hex}"
      propagate_at_launch = true
    },
  ]

  depends_on = ["aws_autoscaling_group.ocp_master"]
}

resource "aws_launch_configuration" "ocp_etcd" {
  name                 = "ocp-etcd-lc-${random_id.suffix.hex}"
  image_id             = "${data.aws_ami.rhel74.id}"
  instance_type        = "${var.etcd_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.setup_role_profile.id}"
  key_name             = "${var.keypair_name}"
  enable_monitoring    = true
  user_data            = "${data.template_cloudinit_config.openshift_etcd.rendered}"

  security_groups = [
    "${aws_security_group.ocp_instances.id}",
    "${aws_security_group.ocp_internal.id}",
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.etcd_root_block_device_size}"
  }
}

data "template_cloudinit_config" "openshift_etcd" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.common_user_data.rendered}"
  }
}
