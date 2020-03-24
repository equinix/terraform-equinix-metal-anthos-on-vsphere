#!/bin/bash



if [ -f "/root/anthos/gkeadm" ] ; then
  echo "Deploying Admin Workstation with gkeadm"
  /root/anthos/gkeadm --config admin-ws-config.yaml
else
  echo "Deploying Admin workstation with terraform"
  terraform init
  terraform apply --auto-approve
fi
