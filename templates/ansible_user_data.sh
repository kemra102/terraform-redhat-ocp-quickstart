#!/usr/bin/env bash

# Based on a template by BASH3 Boilerplate v2.3.0
# http://bash3boilerplate.sh/#authors
#
# The MIT License (MIT)
# Copyright (c) 2013 Kevin van Zonneveld and contributors
# You are not obligated to bundle the LICENSE file with your b3bp projects as long
# as you leave these references intact in the header comments of your source files.

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars.
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace

echo -e "\t------------------[] Check if Subscription is Attached! if not fail Stack"

echo -e "\t------------------[] Start of main execution block"
yum repolist | grep OpenShift
if [[ $? == 0 ]]; then
  echo -e "\t------------------[] Starting OpenShift Configuration"
  echo -e "[INFO] Generating Ansible inventory "
  yum -y install ansible
  sed -i 's/#host_key_checking = False/host_key_checking = False/g' /etc/ansible/ansible.cfg
  aws s3 cp "$SCRIPT_PATH"scripts/get_nodes.py  ~/get_nodes.py
  pip install boto3 &> /var/log/userdata.boto3_install.log || true && qs_err " boto3 install failed "
  python ~/get_nodes.py "${region}" "${ocp_master_asg}" masters > /tmp/openshift_instance-master
  python ~/get_nodes.py "${region}" "${ocp_etcd_asg}" etcd > /tmp/openshift_instances-etcd
  python ~/get_nodes.py "${region}" "${ocp_node_asg}" etcd > /tmp/openshift_instances-nodes
  echo -e "Begin OpenShift configuration"
  aws s3 cp s3://"${qs_s3_bucket_name}"/"${qs_s3_key_prefix}"scripts/openshift_config_ose.yml ~/openshift_config.yml
  cat ~/openshift_config.yml >/etc/ansible/hosts
  echo "${openshift_options}" >> /etc/ansible/hosts
  echo -e "[INFO] Ansible Generated"
  if [[ ${ocp_master_external_elb_dns_name} == 'null' ]]; then
    MASTER_ELBDNSNAME="${ocp_master_internal_elb_dns_name}"
  else
    MASTER_ELBDNSNAME="${ocp_master_external_elb_dns_name}"
  fi
  INTERNAL_MASTER_ELBDNSNAME="${ocp_master_internal_elb_dns_name}"
  NODE_ELBDNSNAME="${ocp_node_internal_elb_dns_name}"
  echo -e "[INFO] Configuring OpenShift Variable"
  {
    echo openshift_master_cluster_hostname="$INTERNAL_MASTER_ELBDNSNAME"
    echo openshift_master_cluster_public_hostname="$MASTER_ELBDNSNAME"
    echo openshift_hostname="$INTERNAL_MASTER_ELBDNSNAME"
  } >> /etc/ansible/hosts

  echo -e "[INFO] Configured OpenShift Variable"
  cat /tmp/openshift_instances-* >> /etc/ansible/hosts
  sed -i 's/#pipelining = False/pipelining = True/g' /etc/ansible/ansible.cfg
  sed -i 's/#log_path/log_path/g' /etc/ansible/ansible.cfg
  echo -e "[INFO] Poll till all nodes are under Ansible (max tries = 50)"
  qs_retry_command 50 ansible -m ping all

  #Install dependencies and update OS
  yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
  yum -y update
  yum -y install atomic-openshift-utils
  yum -y install atomic-openshift-excluder
  PLAYBOOK=${ansible_playbook_type}
  if [ "$PLAYBOOK" == 'Subscription-Version' ]; then
    echo -e "[INFO] Using Builtin Playbooks"
  else
    echo -e "[INFO] Override Builtin Playbooks"
    touch ~/override_Playbooks
    CURRENT_PLAYBOOK_VERSION=https://github.com/openshift/openshift-ansible/archive/openshift-ansible-${ansible_playbook_git_repo_tag}.tar.gz
    curl  --retry 5  -Ls "$CURRENT_PLAYBOOK_VERSION" -o openshift-ansible.tar.gz
    tar -zxf openshift-ansible.tar.gz
    mkdir -p /usr/share/ansible
    mv openshift-ansible-* /usr/share/ansible/openshift-ansible
  fi
  atomic-openshift-excluder unexclude
  echo -e "[INFO] Starting OpenShift Cluster Build (Beginning Ansible Playbook run!!!)"
  date >> ~/playbooks.info
  ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml || true && qs_err " ansible-playbook failed!! "
  date >> ~/playbooks.info
  echo -e "[INFO] Finished OpenShift Cluster Build (Completed Ansible Playbook run!!!)"

  echo -e "[INFO] Adding OpenShift Users"
  ansible masters -a "htpasswd -b /etc/origin/master/htpasswd admin ${openshift_admin_password}"
  echo -e "[INFO] Added OpenShift Users"
  echo -e "[INFO] Finished OpenShift Cluster Build"
  echo -e "\t#################[] End of main execution block "
else
  echo -e " \t#################[] Start of else block "
  echo -e "[REASON] Failed to Acquire OpenShift Entitlement, Check you PoolID and RHN UserName/Password " > ~/failure_reason
  echo -e " \t#################[] End of else block "
  exit 1
fi
