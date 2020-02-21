#!/bin/bash
# TF vars
export VERSION='${anthos_version}'
export GOVC_URL='https://${vmware_fqdn}'
export GOVC_USERNAME='${vmware_username}'
export GOVC_PASSWORD='${vmware_password}'
export GOVC_DATASTORE='${vmware_datastore}'
export GOVC_INSECURE=true

govc import.ova ~/anthos/gke-on-prem-admin-appliance-vsphere-$VERSION.ova
govc vm.markastemplate gke-on-prem-admin-appliance-vsphere-$VERSION
govc pool.create '*/${vmware_resource_pool}'
