#!/bin/bash
# download and install prerequisites:
# * govc
# * terraform
# * admin worksation

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

# ----- statt of mainline code
# Terraform Vars
export VERSION='${anthos_version}'

cd /root/anthos || exit 1

HOSTNAME=$(hostname)

note "# Install GoVC"
xrun wget https://github.com/vmware/govmomi/releases/download/v0.21.0/govc_linux_amd64.gz
xrun gzip -d govc_linux_amd64.gz
chmod +x govc_linux_amd64
mv govc_linux_amd64 /usr/local/bin/govc
rm -f govc_linux_amd64.gz

note "# Install terraform"
xrun wget https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_linux_amd64.zip
xrun unzip terraform_0.12.18_linux_amd64.zip
chmod +x terraform
mv terraform /usr/local/bin
rm -f terraform_0.12.18_linux_amd64.zip

xrun gcloud auth activate-service-account --key-file=$HOME/anthos/gcp_keys/${whitelisted_key_name}

note "# Download and install admin workstation or gkeadm"
if [[ "$VERSION" == 1.1* ]] || [[ "$VERSION" == 1.2* ]] ; then
  xrun gsutil cp gs://gke-on-prem-release/admin-appliance/$VERSION/gke-on-prem-admin-appliance-vsphere-$VERSION.ova ~/anthos/
else
  xrun gsutil cp gs://gke-on-prem-release-public/gkeadm/$VERSION/linux/gkeadm /root/anthos/
  chmod +x /root/anthos/gkeadm
fi

note "# succeeded"
