# terraform-redhat-ocp-quickstart

This Terraform module spins up a Red Hat OpenShift Container Platform within AWS.

It is based on the [AWS Quickstart](https://aws.amazon.com/quickstart/) [quickstart-redhat-openshift](https://github.com/aws-quickstart/quickstart-redhat-openshift) recipe produced by AWS.

This module tries to do away with CloudFormation completely to perform the same task with a pure Terraform code base. There are some deviations from the original template, the most obvious of these is that it is not possible to use an existing VPC, you must allow the module to build the VPC and it's components. There are other smaller changes made in the name of hardening and otherwise making the code more production worthy based on real world deployments with clients.

## Using this Module

In your code you can include the module like this:

```
module "redhat-ocp-quickstart" {
  source = "github.com/kemra102/terraform-redhat-ocp-quickstart"

  keypair_name                  = "ocp"
  redhat_subscription_user_name = "user@example.com"
  redhat_subscription_password  = "password"
  redhat_subscription_pool_id   = "myocppoolid"
  openshift_admin_password      = "password"
}
```

The above shows the minimum amount of variables that must be provided to this module. Additonal variables can be set if you wish to override the defaults. For an explanation of the required variables and the optional ones refer to `inputs.tf` which includes descriptions with each variable.

>NOTE: See the original Quickstart docs for how to get your RHN Pool ID if you are unsure on how to get this.

### Additional Security Group Rules

You can add additional rules to this modules Security Groups by using the `aws_security_group_rule` Terraform resource, for example:

```
resource "aws_security_group_rule" "stop_telneting_out" {
  security_group_id = "${module.redhat-ocp-quickstart.instances_security_group_id}"
  type              = "egress"
  from_port         = 21
  to_port           = 21
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
```

### Additonal Route Table Routes

You can add additional routes to existing Route Tables by using the `aws_route` Terraform resource, for example:

```
resource "aws_route" "peer" {
  route_table_id            = "${module.redhat-ocp-quickstart.public_route_table_id)}"
  destination_cidr_block    = "10.200.1/20"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.logging.id}"
}
```

### Add External ELBs

By default ELBs are only created for the Master & Node instances and both are set to internal. You can optionally enable an external ELB for Master and/or Node instances, for example:

```
module "redhat-ocp-quickstart" {
  source = "github.com/kemra102/terraform-redhat-ocp-quickstart"

  keypair_name                  = "ocp"
  redhat_subscription_user_name = "user@example.com"
  redhat_subscription_password  = "password"
  redhat_subscription_pool_id   = "myocppoolid"
  openshift_admin_password      = "password"
  enable_external_node_elb      = true
}
```

### Changing the Listeners for ELBs

The listeners for ELBs (including external ones you may enable) are defined as variables so can be overriden if desired, for example:

```
variable "my_listeners" {
  default = [
    {
      to_port     = 8080
      from_port   = 8080
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "redhat-ocp-quickstart" {
  source = "github.com/kemra102/terraform-redhat-ocp-quickstart"

  keypair_name                    = "ocp"
  redhat_subscription_user_name   = "user@example.com"
  redhat_subscription_password    = "password"
  redhat_subscription_pool_id     = "myocppoolid"
  openshift_admin_password        = "password"
  enable_external_node_elb        = true
  ocp_node_external_elb_listeners = "${var.my_listeners}"
}
```

## License

All code in this repository unless explicitly stated otherwise is under the [MIT license](https://tldrlegal.com/license/mit-license). Please see the `LICENSE` file for the full legal text of this license.
