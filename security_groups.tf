# Direct access to instances e.g. SSH
resource "aws_security_group" "ocp_instances" {
  name        = "ocp-instances-sg-${random_id.suffix.hex}"
  description = "Allow direct communication to the OpenShift instances."
  vpc_id      = "${aws_vpc.openshift.id}"
  tags        = "${merge(var.default_tags, map("Name", "ocp-instances-sg-${random_id.suffix.hex}"))}"
}

resource "aws_security_group_rule" "ocp_instances_ingress_ssh" {
  security_group_id = "${aws_security_group.ocp_instances.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.remote_access_cidrs}"]
}

resource "aws_security_group_rule" "ocp_instances_egress" {
  security_group_id = "${aws_security_group.ocp_instances.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Internal OCP communication between instances & ELBs
resource "aws_security_group" "ocp_internal" {
  name        = "ocp-internal-sg-${random_id.suffix.hex}"
  description = "Allow communication between all resoruces within the OCP VPC."
  vpc_id      = "${aws_vpc.openshift.id}"
  tags        = "${merge(var.default_tags, map("Name", "ocp-internal-sg-${random_id.suffix.hex}"))}"
}

resource "aws_security_group_rule" "ocp_internal_ingress_ocp" {
  security_group_id = "${aws_security_group.ocp_internal.id}"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
}

# Access to the Master External ELB
resource "aws_security_group" "ocp_master_external" {
  name        = "ocp-master-external-sg-${random_id.suffix.hex}"
  description = "Allow communication to the Master instance's External ELB."
  vpc_id      = "${aws_vpc.openshift.id}"
  tags        = "${merge(var.default_tags, map("Name", "ocp-master-external-sg-${random_id.suffix.hex}"))}"
}

resource "aws_security_group_rule" "ocp_master_external_ingress" {
  security_group_id = "${aws_security_group.ocp_master_external.id}"
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = ["${var.remote_access_cidrs}"]
}

# Access to the Node External ELB
resource "aws_security_group" "ocp_node_external" {
  name        = "ocp-node-external-sg-${random_id.suffix.hex}"
  description = "Allow communication to the Node instance's External ELB."
  vpc_id      = "${aws_vpc.openshift.id}"
  tags        = "${merge(var.default_tags, map("Name", "ocp-node-external-sg-${random_id.suffix.hex}"))}"
}

resource "aws_security_group_rule" "ocp_node_external_ingress" {
  security_group_id = "${aws_security_group.ocp_master_external.id}"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${var.remote_access_cidrs}"]
}
