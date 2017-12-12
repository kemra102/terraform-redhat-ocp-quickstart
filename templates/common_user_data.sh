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

echo -e "========================================================================================================================"
echo -e "\t------------------[] Starting: NetworkManager configuration"
yum -y install NetworkManager
systemctl start NetworkManager && systemctl enable  NetworkManager
echo -e "\t------------------[] Finished: NetworkManager configuration"
echo -e "========================================================================================================================"

echo -e "========================================================================================================================"
echo -e "\t------------------[] Starting: SSH Pub Key configuration"
pub_key_path='/root/.ssh/public.key'
echo "${pub_key}" > "$pub_key_path"
chmod 400 "$pub_key_path"
chown root:root "$pub_key_path"
cat "$pub_key_path" >> /root/.ssh/authorized_keys
echo -e "\t------------------[] Finished: SSH Pub Key configuration"
echo -e "========================================================================================================================"

echo -e "========================================================================================================================"
echo -e "\t------------------[] Starting: Load QuickStart Common"

QSLOCATION="https://${qs_s3_bucket_name}.s3.amazonaws.com/${qs_s3_key_prefix}"
UTIL="$QSLOCATION"submodules/quickstart-linux-utilities/quickstart-cfn-tools.source
P=/tmp/quickstart-cfn-tools.source

#qs_retry_command is not available (use until loop)
n=0 # This stops bash giving an unbound variable error
curl --retry 10 -s "$UTIL" -o "$P" || n=0; until [[ $n -ge 50 ]]; do curl -s "$UTIL" -o "$P" && break; n=$((n+1)); done
source $P
echo -e "\t------------------[] Finished: Load QuickStart Common"
echo -e "========================================================================================================================"

echo -e "\t------------------[] Starting: aws cfn-bootstrap installation via [qs_bootstrap_pip, qs_aws-cfn-bootstrap]"
qs_bootstrap_pip || true && qs_err " pip bootstrap failed "
qs_aws-cfn-bootstrap || true && qs_err " cfn bootstrap failed "
echo -e "\t------------------[] Finished: aws cfn-bootstrap installation"

echo -e "\t------------------[] Starting: epel configuration via [qs_enable_epel]"
# Needed for initial Ansible availability
qs_enable_epel &> /var/log/userdata.qs_enable_epel.log || true && qs_err " enable epel failed "
echo -e "\t------------------[] Completed epel configuration "

echo -e "\t------------------[] Starting: installation of  awscli "
pip install awscli  &> /var/log/userdata.awscli_install.log || true && qs_err " awscli install failed "
echo -e "\t------------------[] Completed: install of awscli "

echo -e "========================================================================================================================"
echo -e "\t------------------[] Completed: QuickStart Common Utils "

echo -e "========================================================================================================================"
echo -e "\t------------------[]Attach to Subscription pool"
SCRIPT_PATH="s3://${qs_s3_bucket_name}/${qs_s3_key_prefix}"
aws s3 cp "$SCRIPT_PATH"scripts/redhat_ose-register.sh  ~/redhat_ose-register.sh
chmod 755 ~/redhat_ose-register.sh
qs_retry_command 20 ~/redhat_ose-register.sh "${redhat_subscription_user_name}" "${redhat_subscription_password}" "${redhat_subscription_pool_id}"

echo -e "========================================================================================================================"

yum install -y atomic-openshift-docker-excluder \
  atomic-openshift-node \
  atomic-openshift-sdn-ovs \
  ceph-common \
  conntrack-tools \
  dnsmasq \
  docker \
  docker-client \
  docker-common \
  docker-rhel-push-plugin \
  glusterfs \
  glusterfs-client-xlators \
  glusterfs-fuse \
  glusterfs-libs \
  iptables-services \
  iscsi-initiator-utils \
  iscsi-initiator-utils-iscsiuio \
  tuned-profiles-atomic-openshift-node
