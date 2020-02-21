#!/bin/bash
cd /home/ubuntu/cluster/
export GOVC_URL='https://${vcenter_fqdn}/sdk'
export GOVC_USERNAME='${vcenter_user}'
export GOVC_PASSWORD='${vcenter_pass}'
export GOVC_INSECURE=true

govc datastore.mkdir -dc="${vcenter_datacenter}" -ds="${vcenter_datastore}" gke-on-prem/

gcloud auth activate-service-account --key-file=/home/ubuntu/cluster/${whitelisted_key_name}
gcloud auth configure-docker --quiet

openssl s_client -showcerts -verify 5 -connect ${vcenter_fqdn}:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="vspherecert.pem"; print >out}'

export SYLLOGI_FEATURE_GATES="EnableBundledLB=true"

gkectl check-config --config /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml
gkectl prepare --config /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml  --skip-validation-all
gkectl create loadbalancer --config /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml  --skip-validation-all
gkectl create cluster --config /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml --skip-validation-all

	

