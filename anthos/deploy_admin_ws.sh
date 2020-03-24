#!/bin/bash

export WORKSTATIONIP=__IP_ADDRESS__

if [ -f "/root/anthos/gkeadm" ] ; then
  echo "Deploying Admin Workstation with gkeadm"
  openssl s_client -showcerts -verify 5 -connect ${vcenter_fqdn}:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="/root/anthos/vspherecert.pem"; print >out}'
  /root/anthos/gkeadm create admin-workstation --config /root/anthos/admin-ws-config.yaml
  
  export KEY=$(cat /root/anthos/ssh_key.pub)
  
  ssh -i /root/.ssh/gke-admin-workstation ubuntu@$WORKSTATIONIP 'echo "$KEY" >> /home/ubuntu/.ssh/authorized_keys'

else
  echo "Deploying Admin Workstation with terraform"
  terraform init
  terraform apply --auto-approve
fi
