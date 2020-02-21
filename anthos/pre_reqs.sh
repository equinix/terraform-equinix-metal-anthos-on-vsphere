#!/bin/bash
# Terraform Vars
export VERSION='${anthos_version}'

cd /root/anthos

# Install GoVC
wget https://github.com/vmware/govmomi/releases/download/v0.21.0/govc_linux_amd64.gz
gzip -d govc_linux_amd64.gz
chmod +x govc_linux_amd64
mv govc_linux_amd64 /usr/local/bin/govc
rm -f govc_linux_amd64.gz

# Install terraform
wget https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_linux_amd64.zip
unzip terraform_0.12.18_linux_amd64.zip
chmod +x terraform
mv terraform /usr/local/bin
rm -f terraform_0.12.18_linux_amd64.zip

# Download and deploy admin workstation
gcloud auth activate-service-account --key-file=$HOME/anthos/gcp_keys/${whitelisted_key_name}
gsutil cp gs://gke-on-prem-release/admin-appliance/$VERSION/gke-on-prem-admin-appliance-vsphere-$VERSION.ova ~/anthos/

