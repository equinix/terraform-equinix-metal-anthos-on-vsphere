#!/bin/bash

# print a message to stderr, prefixed by HOSTNAME
function note() {
  echo 1>&2 "$HOSTNAME: $*"
}

# print the given command to stderr, run it, and exit verbosely if it fails.
function xrun() {
  note "+ $@"
  "$@" && return 0
  local xstat=$?
  note "Cmd $1 failed, exit $xstat"
  exit "$xstat"
}

# ----- start of mainline code

HOSTNAME=$(hostname)

# TF vars
export VERSION='${anthos_version}'
export GOVC_URL='https://${vmware_fqdn}'
export GOVC_USERNAME='${vmware_username}'
export GOVC_PASSWORD='${vmware_password}'
export GOVC_DATASTORE='${vmware_datastore}'
export GOVC_INSECURE=true


if [ ! -f "/root/anthos/gkeadm" ] ; then
  xrun govc import.ova ~/anthos/gke-on-prem-admin-appliance-vsphere-$VERSION.ova
  xrun govc vm.markastemplate gke-on-prem-admin-appliance-vsphere-$VERSION
fi

xrun govc pool.create '*/${vmware_resource_pool}'

note "# succeeded"
