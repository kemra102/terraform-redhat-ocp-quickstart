resource "aws_vpc" "openshift" {
  cidr_block = "${var.vpc_cidr}"
  tags       = "${merge(var.default_tags, map("Name", "openshift"))}"
}

resource "aws_internet_gateway" "openshift" {
  vpc_id = "${aws_vpc.openshift.id}"
  tags   = "${merge(var.default_tags, map("Name", "openshift"))}"
}

resource "aws_subnet" "openshift_private" {
  count = "${length(data.aws_availability_zones.available.names)}"

  vpc_id            = "${aws_vpc.openshift.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr, 8, count.index)}"
  tags              = "${merge(var.default_tags, map("Name", "openshift-private-${count.index}"))}"
}

resource "aws_subnet" "openshift_public" {
  count = "${length(data.aws_availability_zones.available.names)}"

  vpc_id            = "${aws_vpc.openshift.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr, 8, count.index + 10)}"
  tags              = "${merge(var.default_tags, map("Name", "openshift-public-${count.index}"))}"
}

resource "aws_route_table" "openshift_private" {
  count = "${length(data.aws_availability_zones.available.names)}"

  vpc_id = "${aws_vpc.openshift.id}"
  tags   = "${merge(var.default_tags, map("Name", "openshift-private-${count.index}"))}"
}

resource "aws_route" "openshift_private_internet" {
  count = "${length(data.aws_availability_zones.available.names)}"

  route_table_id         = "${element(aws_route_table.openshift_private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.openshift.*.id, count.index)}"
}

resource "aws_route_table" "openshift_public" {
  vpc_id = "${aws_vpc.openshift.id}"
  tags   = "${merge(var.default_tags, map("Name", "openshift-public"))}"
}

resource "aws_route" "openshift_public_internet" {
  route_table_id         = "${aws_route_table.openshift_public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.openshift.id}"
}

resource "aws_route_table_association" "openshift_private" {
  count = "${length(data.aws_availability_zones.available.names)}"

  subnet_id      = "${element(aws_subnet.openshift_private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.openshift_private.*.id, count.index)}"
}

resource "aws_route_table_association" "openshift_public" {
  count = "${length(data.aws_availability_zones.available.names)}"

  subnet_id      = "${element(aws_subnet.openshift_public.*.id, count.index)}"
  route_table_id = "${aws_route_table.openshift_public.id}"
}

data "aws_availability_zones" "available" {}

resource "aws_nat_gateway" "openshift" {
  count = "${length(data.aws_availability_zones.available.names)}"

  allocation_id = "${element(aws_eip.openshift.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.openshift_public.*.id, count.index)}"
  tags          = "${merge(var.default_tags, map("Name", "openshift-${count.index}"))}"
}

resource "aws_eip" "openshift" {
  count = "${length(data.aws_availability_zones.available.names)}"

  vpc = true
}
