#!/bin/bash

# print a message to stderr, prefixed by HOSTNAME
function note() {
  echo 1>&2 "$HOSTNAME: $*"
}

# print the given command to stderr, run it, and return the exit status.
function vrun() {
  note "+ $@"
  "$@"
}

# print the given command to stderr, run it, and exit verbosely if it fails.
function xrun() {
  note "+ $@"
  "$@" && return 0
  local xstat=$?
  note "Cmd $1 failed, exit $xstat"
  exit "$xstat"
}

# fetch the pem from the given address, and print to stdout.
fetch_pem() {
  local addr=$1
  xrun openssl s_client -showcerts -verify 5 -connect ${vcenter_fqdn}:443 < /dev/null \
  | awk '/BEGIN/,/END/ {print}'
  return "$((PIPESTATUS[0]))"
}

# ----- start of mainline code

PROGNAME=bundled-lb-install-script.sh
HOSTNAME=$(hostname)

FILEPATH=/home/ubuntu/cluster/
CONFIG=bundled-lb-admin-uc1-config.yaml
ADCONFIG=admin-cluster-config.yaml
USERCONFIG=user-cluster1-config.yaml
ADKUBECONFIG=kubeconfig

note "# Begin $PROGNAME"


cd $FILEPATH || exit 1
export GOVC_URL='https://${vcenter_fqdn}/sdk'
export GOVC_USERNAME='${vcenter_user}'
export GOVC_PASSWORD='${vcenter_pass}'
export GOVC_INSECURE=true
VERSION=$(gkectl version | awk '{print $2}')
ESXICOUNT='${esxi_host_count}'


# in some versions of anthos, this command may fail harmlessly
vrun govc datastore.mkdir -dc="${vcenter_datacenter}" -ds="${vcenter_datastore}" gke-on-prem/

xrun gcloud auth activate-service-account --key-file=/home/ubuntu/cluster/${whitelisted_key_name}
xrun gcloud auth configure-docker --quiet

fetch_pem ${vcenter_fqdn}:443 > vspherecert.pem

if [[ "$VERSION" == 1.1* ]] || [[ "$VERSION" == 1.2* ]] ; then
  export SYLLOGI_FEATURE_GATES="EnableBundledLB=true"
else
  if (( "$ESXICOUNT" > "1" )) ; then
    sed -i 's/enabled: false/enabled: true/' $FILEPATH$CONFIG
    sed -i 's/enbableha: false/enableha: true/g' $FILEPATH$CONFIG
    sed -i 's/enabled: false/enabled: true/' $FILEPATH$ADCONFIG
    sed -i 's/enabled: false/enabled: true/' $FILEPATH$USERCONFIG
    sed -i 's/enableHA: false/enableHA: true/g' $FILEPATH$ADCONFIG
    sed -i 's/enableHA: false/enableHA: true/g' $FILEPATH$USERCONFIG
  fi
fi


if [[ "$VERSION" == 1.1* ]] || [[ "$VERSION" == 1.2* ]] || [[ "$VERSION" == 1.3* ]]; then
  xrun gkectl check-config --config $FILEPATH$CONFIG --fast
  xrun gkectl prepare --config $FILEPATH$CONFIG  --skip-validation-all
  xrun gkectl create loadbalancer --config $FILEPATH$CONFIG --skip-validation-all

  if [[ "$VERSION" == 1.1* ]] || [[ "$VERSION" == 1.2* ]] ; then
    echo "EAP version of bundled LB detected, deleting redundant LBs"
    VM1=$(tail -1 seesaw-for-gke-admin.yaml | sed 's/^.\{2\}//' )
    VM2=$(tail -1 seesaw-for-${anthos_user_cluster_name}.yaml | sed 's/^.\{2\}//')
    govc vm.destroy $VM1
    govc vm.destroy $VM2
  fi

  xrun gkectl create cluster --config $FILEPATH$CONFIG --skip-validation-all
else
  xrun gkectl check-config --config $FILEPATH$ADCONFIG --fast
  xrun gkectl prepare --config $FILEPATH$ADCONFIG --skip-validation-all
  xrun gkectl create loadbalancer --config $FILEPATH$ADCONFIG --skip-validation-all
  xrun gkectl create admin --config $FILEPATH$ADCONFIG --skip-validation-all
  xrun gkectl check-config --config $FILEPATH$USERCONFIG  --kubeconfig $FILEPATH$ADKUBECONFIG
  xrun gkectl create loadbalancer --config $FILEPATH$USERCONFIG  --kubeconfig $FILEPATH$ADKUBECONFIG --skip-validation-all
  xrun gkectl create cluster --config $FILEPATH$USERCONFIG  --kubeconfig $FILEPATH$ADKUBECONFIG --skip-validation-all
fi

note "# End $PROGNAME - success"
