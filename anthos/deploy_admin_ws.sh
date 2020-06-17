#!/bin/bash

export WORKSTATIONIP=__IP_ADDRESS__

if [ -f "/root/anthos/gkeadm" ] ; then
  echo "Deploying Admin Workstation with gkeadm"
  echo "*************************************************************************"
  echo "** Errors in the follwing section related to enabling API and creating **"
  echo "** IAM roles are expected and can safely be ignored                    **"
  echo "*************************************************************************"
  openssl s_client -showcerts -verify 5 -connect ${vcenter_fqdn}:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="/root/anthos/vspherecert.pem"; print >out}'
  /root/anthos/gkeadm create admin-workstation --config /root/anthos/admin-ws-config.yaml --ssh-key-path /root/anthos/ssh_key --skip-validation
  echo "*************************************************************************"
  echo "** Errors in the above section related to enabling API and creating    **"
  echo "** IAM roles are expected and can safely be ignored                    **"
  echo "*************************************************************************"
else
  echo "Deploying Admin Workstation with terraform"
  terraform init
  terraform apply --auto-approve
fi
