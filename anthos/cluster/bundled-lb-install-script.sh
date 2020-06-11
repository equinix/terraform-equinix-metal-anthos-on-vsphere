#!/bin/bash
cd /home/ubuntu/cluster/
export GOVC_URL='https://${vcenter_fqdn}/sdk'
export GOVC_USERNAME='${vcenter_user}'
export GOVC_PASSWORD='${vcenter_pass}'
export GOVC_INSECURE=true
VERSION=$(gkectl version | awk '{print $2}')
ESXICOUNT='${esxi_host_count}'

govc datastore.mkdir -dc="${vcenter_datacenter}" -ds="${vcenter_datastore}" gke-on-prem/

gcloud auth activate-service-account --key-file=/home/ubuntu/cluster/${whitelisted_key_name}
gcloud auth configure-docker --quiet

openssl s_client -showcerts -verify 5 -connect ${vcenter_fqdn}:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="vspherecert.pem"; print >out}'

if [[ "$VERSION" == 1.1* ]] || [[ "$VERSION" == 1.2* ]] ; then
  export SYLLOGI_FEATURE_GATES="EnableBundledLB=true"
else
  if (( "$ESXICOUNT" > "1" )) ; then
    sed -i 's/enabled: false/enabled: true/' /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml
    sed -i 's/#X//g' /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml
  fi
fi


gkectl check-config --config /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml --fast
gkectl prepare --config /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml  --skip-validation-all
gkectl create loadbalancer --config /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml  --skip-validation-all

if [[ "$VERSION" == 1.1* ]] || [[ "$VERSION" == 1.2* ]] ; then
	echo "EAP version of bundled LB detected, deleting redundant LBs"
	VM1=$(tail -1 seesaw-for-gke-admin.yaml | sed 's/^.\{2\}//' )
	VM2=$(tail -1 seesaw-for-${anthos_user_cluster_name}.yaml | sed 's/^.\{2\}//')
	govc vm.destroy $VM1
	govc vm.destroy $VM2
fi

gkectl create cluster --config /home/ubuntu/cluster/bundled-lb-admin-uc1-config.yaml --skip-validation-all

