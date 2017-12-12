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

# Configure Storage
systemctl enable docker.service
systemctl start docker.service
{
  echo -e "CONTAINER_THINPOOL=docker-pool"
  echo -e "DEVS=/dev/xvdb"
  echo -e "VG=docker-vg"
  echo -e "STORAGE_DRIVER=devicemapper"
} >> /etc/sysconfig/docker-storage-setup
docker-storage-setup
rm -rf /var/lib/docker
systemctl restart docker
