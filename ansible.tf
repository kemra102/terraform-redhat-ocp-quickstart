resource "aws_instance" "ansible_config_server" {
  ami                  = "${data.aws_ami.rhel74.id}"
  instance_type        = "${var.ansible_instance_type}"
  key_name             = "${var.keypair_name}"
  monitoring           = true
  subnet_id            = "${aws_subnet.openshift_private.0.id}"
  iam_instance_profile = "${aws_iam_instance_profile.setup_role_profile.id}"
  user_data            = "${data.template_cloudinit_config.ansible.rendered}"
  tags                 = "${merge(var.default_tags, map("Name", "ansible-config-server-${random_id.suffix.hex}"))}"

  vpc_security_group_ids = [
    "${aws_security_group.ocp_instances.id}",
    "${aws_security_group.ocp_internal.id}",
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
  }

  depends_on = ["aws_autoscaling_group.ocp_node"]
}

data "template_cloudinit_config" "ansible" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.common_user_data.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${element(concat(data.template_file.ansible_user_data.rendered, data.template_file.ansible_user_data_extern.rendered), 0)}"
    content      = "${data.template_file.ansible_user_data.rendered}"
  }
}

data "template_file" "ansible_user_data_extern" {
  count = "${var.enable_external_master_elb}"

  template = "${file("${path.module}/templates/ansible_user_data.sh")}"

  vars {
    ocp_master_asg                   = "${aws_autoscaling_group.ocp_master.name}"
    ocp_etcd_asg                     = "${aws_autoscaling_group.ocp_etcd.name}"
    ocp_node_asg                     = "${aws_autoscaling_group.ocp_node.name}"
    ocp_master_internal_elb          = "${aws_elb.ocp_master_internal.name}"
    region                           = "${data.aws_region.current.name}"
    qs_s3_bucket_name                = "${var.qs_s3_bucket_name}"
    qs_s3_key_prefix                 = "${var.qs_s3_key_prefix}"
    openshift_options                = "${var.openshift_options}"
    ocp_master_external_elb_dns_name = "${aws_elb.ocp_master_external.dns_name}"
    ocp_master_internal_elb_dns_name = "${aws_elb.ocp_master_internal.dns_name}"
    ocp_node_internal_elb_dns_name   = "${aws_elb.ocp_node_internal.dns_name}"
    ansible_playbook_type            = "${var.ansible_playbook_type}"
    ansible_playbook_git_repo_tag    = "${var.ansible_playbook_git_repo_tag}"
    ocp_admin_password               = "${var.openshift_admin_password}"
  }
}

data "template_file" "ansible_user_data" {
  count = "${1 - var.enable_external_master_elb}"

  template = "${file("${path.module}/templates/ansible_user_data.sh")}"

  vars {
    ocp_master_asg                   = "${aws_autoscaling_group.ocp_master.name}"
    ocp_etcd_asg                     = "${aws_autoscaling_group.ocp_etcd.name}"
    ocp_node_asg                     = "${aws_autoscaling_group.ocp_node.name}"
    ocp_master_internal_elb          = "${aws_elb.ocp_master_internal.name}"
    region                           = "${data.aws_region.current.name}"
    qs_s3_bucket_name                = "${var.qs_s3_bucket_name}"
    qs_s3_key_prefix                 = "${var.qs_s3_key_prefix}"
    openshift_options                = "${var.openshift_options}"
    ocp_master_external_elb_dns_name = "null"
    ocp_master_internal_elb_dns_name = "${aws_elb.ocp_master_internal.dns_name}"
    ocp_node_internal_elb_dns_name   = "${aws_elb.ocp_node_internal.dns_name}"
    ansible_playbook_type            = "${var.ansible_playbook_type}"
    ansible_playbook_git_repo_tag    = "${var.ansible_playbook_git_repo_tag}"
    ocp_admin_password               = "${var.openshift_admin_password}"
  }
}
