variable "keypair_name" {
  description = "Name of an existing EC2 key pair. All instances will launch with this key pair."
}

variable "qs_s3_bucket_name" {
  description = "S3 bucket name for the Quick Start assets."
  default     = "quickstart-reference"
}

variable "qs_s3_key_prefix" {
  description = "S3 key prefix for the Quick Start assets."
  default     = "redhat/openshift/latest/"
}

variable "remote_access_cidrs" {
  description = "The CIDR IP ranges that are permitted to access OCP."
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "openshift_admin_password" {
  description = "Password for OpenShift Admin UI."
}

variable "openshift_options" {
  description = "(Optional) Leave Blank Unless"
  default     = ""
}

variable "redhat_subscription_user_name" {
  description = "RHN User Name."
}

variable "redhat_subscription_password" {
  description = "RHN Password."
}

variable "redhat_subscription_pool_id" {
  description = "RHN Pool ID."
}

variable "ansible_playbook_type" {
  description = "Version of the Ansible Playbook used to deploy OCP (allowed values are 'Subscription-Version' & 'OpenSource-Version'). The Open Source should only be used for development purposes."
  default     = "Subscription-Versions"
}

variable "ansible_playbook_git_repo_tag" {
  description = "Only Used if 'OpenSource-Version' is selected. List of Development Releases available here -> https://github.com/openshift/openshift-ansible/releases"
  default     = "3.6.173.0.5-5"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "enable_external_master_elb" {
  description = "Set to true if an external ELB is required for accessing the Master instances."
  default     = false
}

variable "enable_external_node_elb" {
  description = "Set to true if an external ELB is required for accessing the Node instances."
  default     = false
}

variable "ocp_master_external_elb_listeners" {
  description = "A list of hashes of listeners to be used by the OCP Master External ELB."
  type        = "list"
  default     = [
    {
      instance_port     = 8443
      instance_protocol = "TCP"
      lb_port           = 8443
      lb_protocol       = "TCP"
    }
  ]
}

variable "ocp_master_internal_elb_listeners" {
  description = "A list of hashes of listeners to be used by the OCP Master Internal ELB."
  type        = "list"
  default     = [
    {
      instance_port     = 80
      instance_protocol = "TCP"
      lb_port           = 80
      lb_protocol       = "TCP"
    },
    {
      instance_port     = 443
      instance_protocol = "TCP"
      lb_port           = 443
      lb_protocol       = "TCP"
    },
    {
      instance_port     = 8443
      instance_protocol = "TCP"
      lb_port           = 8443
      lb_protocol       = "TCP"
    }
  ]
}

variable "ocp_node_external_elb_listeners" {
  description = "A list of hashes of listeners to be used by the OCP Node External ELB."
  type        = "list"
  default     = [
    {
      instance_port     = 443
      instance_protocol = "TCP"
      lb_port           = 443
      lb_protocol       = "TCP"
    }
  ]
}

variable "ocp_node_internal_elb_listeners" {
  description = "A list of hashes of listeners to be used by the OCP Node Internal ELB."
  type        = "list"
  default     = [
    {
      instance_port     = 8443
      instance_protocol = "TCP"
      lb_port           = 8443
      lb_protocol       = "TCP"
    }
  ]
}

variable "master_instance_type" {
  description = "Type of EC2 Instance for the OCP Masters."
  default     = "m4.xlarge"
}

variable "etcd_instance_type" {
  description = "Type of EC2 Instance for the OCP Etcds."
  default     = "m4.xlarge"
}

variable "node_instance_type" {
  description = "Type of EC2 Instance for the OCP Nodes."
  default     = "m4.2xlarge"
}

variable "ansible_instance_type" {
  description = "Type of EC2 Instance for the Ansible Config Server."
  default     = "t2.medium"
}

variable "number_of_nodes" {
  description = "Number of OCP Nodes."
  default     = "3"
}

variable "master_root_block_device_size" {
  description = "Size of the root block device for the OCP Masters."
  default     = 100
}

variable "etcd_root_block_device_size" {
  description = "Size of the root block device for the OCP Etcds."
  default     = 120
}

variable "node_root_block_device_size" {
  description = "Size of the root block device for the OCP Nodes."
  default     = 80
}

variable "node_data_block_device_size" {
  description = "Size of the data block device for the OCP Nodes."
  default     = 120
}

variable "default_tags" {
  description = "The default tags that should be applied to all non-ASG taggable resources across this module."
  type        = "map"

  default = {
    "terraform:module" = "redhat-ocp-quickstart"
  }
}

variable "default_asg_tags" {
  description = "A list of maps of tags to apply to the Autoscaling Groups across the module."
  type        = "list"

  default = [
    {
      key                 = "terraform:module"
      value               = "redhat-ocp-quickstart"
      propagate_at_launch = true
    },
  ]
}

data "aws_ami" "rhel74" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-7.4_HVM_GA-20170808-x86_64-2-Hourly2-GP2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "template_file" "common_user_data" {
  template = "${file("${path.module}/templates/common_user_data.sh")}"

  vars {
    pub_key                       = "${lookup(aws_cloudformation_stack.get_rsa.outputs, "PublicKey")}"
    qs_s3_bucket_name             = "${var.qs_s3_bucket_name}"
    qs_s3_key_prefix              = "${var.qs_s3_key_prefix}"
    redhat_subscription_user_name = "${var.redhat_subscription_user_name}"
    redhat_subscription_password  = "${var.redhat_subscription_password}"
    redhat_subscription_pool_id   = "${var.redhat_subscription_pool_id}"
  }
}

data "aws_region" "current" {
  current = true
}
