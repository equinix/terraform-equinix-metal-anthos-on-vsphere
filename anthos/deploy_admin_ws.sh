#!/bin/bash

export WORKSTATIONIP=__IP_ADDRESS__

if [ -f "/root/anthos/gkeadm" ] ; then
  echo "Deploying Admin Workstation with gkeadm"
  openssl s_client -showcerts -verify 5 -connect ${vcenter_fqdn}:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="/root/anthos/vspherecert.pem"; print >out}'
  /root/anthos/gkeadm create admin-workstation --config /root/anthos/admin-ws-config.yaml
  scp -i /root/.ssh/gke-admin-workstation /root/anthos/ssh_key.pub ubuntu@$WORKSTATIONIP:/home/ubuntu/.ssh/ssh_key.pub
  ssh -i /root/.ssh/gke-admin-workstation ubuntu@$WORKSTATIONIP 'echo "$(cat /home/ubuntu/.ssh/ssh_key.pub)" >> /home/ubuntu/.ssh/authorized_keys'
else
  echo "Deploying Admin Workstation with terraform"
  terraform init
  terraform apply --auto-approve
fi
