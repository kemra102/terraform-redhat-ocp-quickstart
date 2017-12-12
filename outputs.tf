output "private_route_table_ids" {
  value = "${aws_route_table.openshift_private.*.id}"
}

output "public_route_table_id" {
  value = "${aws_route_table.openshift_public.id}"
}

output "instances_security_group_id" {
  value = "${aws_security_group.ocp_instances.id}"
}

output "internal_security_group_id" {
  value = "${aws_security_group.ocp_internal.id}"
}

output "master_external_elb_security_group_id" {
  value = "${aws_security_group.ocp_master_external.id}"
}
