#!/bin/bash

# print a message to stderr, prefixed by HOSTNAME
function note() {
  echo 1>&2 "$HOSTNAME: $*"
}

# print the given command to stderr, run it, and exit verbosely if it fails.
function xrun() {
  vrun "$@" && return 0

  local xstat=$?
  note "Cmd $1 failed, exit $xstat"
  exit "$xstat"
}

# print the given command to stderr, run it.  return the status
function vrun() {
  note "+ $@"
  "$@"
}

# fetch the vcenter pem from the givem host:port, and print it to stdout.
function fetch_pem() {
  local addr=$1
  xrun openssl s_client -showcerts -verify 5 -connect "$addr" < /dev/null \
  | awk '/BEGIN/,/END/ {print}'
  return "$((PIPESTATUS[0]))"
}

# ----- statt of mainline code

HOSTNAME=$(hostname)

export WORKSTATIONIP=__IP_ADDRESS__

if [ -f "/root/anthos/gkeadm" ] ; then
  echo "Deploying Admin Workstation with gkeadm"
  echo "**********************#****************************************************"
  echo "** Errors in the following section related to enabling APIs and creating **"
  echo "** IAM roles are expected and can safely be ignored                      **"
  echo "***********************#***************************************************"
  fetch_pem ${vcenter_fqdn}:443 > /root/anthos/vspherecert.pem || exit 1
  vrun /root/anthos/gkeadm create admin-workstation --config /root/anthos/admin-ws-config.yaml --ssh-key-path /root/anthos/ssh_key --skip-validation
  echo "*************************************************************************"
  echo "** Errors in the above section related to enabling APIs and creating   **"
  echo "** IAM roles are expected and can safely be ignored                    **"
  echo "*************************************************************************"
else
  echo "Deploying Admin Workstation with terraform"
  xrun terraform init
  xrun terraform apply --auto-approve
fi

note "# succeeded"
