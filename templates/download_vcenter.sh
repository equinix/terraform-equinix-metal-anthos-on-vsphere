#!/bin/bash

SSH_PRIVATE_KEY='${ssh_private_key}'

s3_boolean=`echo "${s3_boolean}" | awk '{print tolower($0)}'`
cd /root/anthos


cat <<EOF >/root/.ssh/esxi_key
$SSH_PRIVATE_KEY
EOF
chmod 0400 /root/.ssh/esxi_key

echo "Set SSH config to not do StrictHostKeyChecking"
cat <<EOF >/root/.ssh/config
Host *
    StrictHostKeyChecking no
EOF
chmod 0400 /root/.ssh/config

while [ ! -f /usr/lib/google-cloud-sdk/platform/gsutil/gsutil ] ;
do
  echo "Waiting for gsutil to become available"
  sleep 10
done

sleep 60

cd /root/
if [ $s3_boolean = "false" ]; then
  echo "USING GCS"
  gcloud auth activate-service-account --key-file=$HOME/anthos/gcp_keys/${storage_reader_key_name}
  gsutil cp gs://${gcs_bucket_name}/${vcenter_iso_name} .
  gsutil cp gs://${gcs_bucket_name}/vsanapiutils.py .
  gsutil cp gs://${gcs_bucket_name}/vsanmgmtObjects.py .
else
  echo "USING S3"
  curl -LO https://dl.min.io/client/mc/release/linux-amd64/mc
  chmod +x mc
  mv mc /usr/local/bin/
  mc config host add s3 ${s3_url} ${s3_access_key} ${s3_secret_key}
  mc cp s3/${s3_bucket_name}/${vcenter_iso_name} .
  mc cp s3/${s3_bucket_name}/vsanapiutils.py .
  mc cp s3/${s3_bucket_name}/vsanmgmtObjects.py .
fi
mount /root/${vcenter_iso_name} /mnt/

