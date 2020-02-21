#!/bin/bash
s3_boolean=`echo "${s3_boolean}" | awk '{print tolower($0)}'`
cd /root/anthos

# Kill apt-daily-upgrade incase it is running
#systemctl disable apt-daily.timer
#systemctl disable apt-daily-upgrade.timer

#systemctl stop unattended-upgrades.service
#systemctl stop apt-daily.service
#systemctl stop apt-daily-upgrade.service



# Install google cloud sdk
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update -y
apt-get install unzip google-cloud-sdk=272.0.0-0 -y

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

#restart services
#systemctl enable apt-daily.timer
#systemctl enable apt-daily-upgrade.timer
