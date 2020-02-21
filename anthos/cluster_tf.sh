#!/bin/bash
cat <<EOF >/root/anthos/ksa_token.txt
NO CLUSTER WAS DEPLOYED. NO KSA TOKEN HAS BEEN CREATED.
EOF
deployCluster=`echo "${anthos_deploy_clusters}" | awk '{print tolower($0)}'`
cp /root/anthos/gcp_keys/* /root/anthos/cluster/
if [ $deployCluster == "true" ]; then
  echo "DEPLOYING ANTHOS CLUSTERS!"
  cd /root/anthos/cluster
  terraform init
  terraform apply --auto-approve
  exit 0
else
  echo "SKIPPING ANTHOS CLUSTER DEPLOY!"
fi

