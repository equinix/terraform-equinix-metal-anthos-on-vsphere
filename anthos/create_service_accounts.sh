#!/bin/bash
echo "This script will help you perform the setps outlined at https://cloud.google.com/gke-on-prem/docs/how-to/service-accounts \nYou will be provided the option to create a storage reader service account as well. \n\n"
echo "Enter the name of the email of your whitelisted service account \n (example: whitelisted@my-anthos-project.iam.gserviceaccount.com):"
read WL_SA_EMAIL
echo "Create storage reader account? (y/n)"
read STORAGE_OPTION
if [ $STORAGE_OPTION = "y" ]; then
    echo "Provide Project where GCS Bucket Lives"
    read STORAGE_PROJECT
fi
gcloud init
PROJECT=$(gcloud config list --format 'value(core.project)')
FOLDER='gcp_keys'
mkdir -p ./$FOLDER
gcloud iam service-accounts create register-service-account --project $PROJECT
gcloud iam service-accounts create connect-service-account --project $PROJECT
gcloud iam service-accounts create stackdriver-service-account --project $PROJECT
gcloud iam service-accounts keys create ./$FOLDER/register-key.json --iam-account  register-service-account@$PROJECT.iam.gserviceaccount.com 
gcloud iam service-accounts keys create ./$FOLDER/connect-key.json --iam-account  connect-service-account@$PROJECT.iam.gserviceaccount.com 
gcloud iam service-accounts keys create ./$FOLDER/stackdriver-key.json --iam-account  stackdriver-service-account@$PROJECT.iam.gserviceaccount.com 
gcloud iam service-accounts keys create ./$FOLDER/whitelisted-key.json --iam-account  $WL_SA_EMAIL
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:connect-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/gkehub.connect'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:register-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/gkehub.admin'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:register-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/serviceusage.serviceUsageViewer'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:stackdriver-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/stackdriver.resourceMetadata.writer'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:stackdriver-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/logging.logWriter'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:stackdriver-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/monitoring.metricWriter'

gcloud services enable --project $PROJECT \
    cloudresourcemanager.googleapis.com \
    container.googleapis.com \
    gkeconnect.googleapis.com \
    gkehub.googleapis.com \
    serviceusage.googleapis.com \
    stackdriver.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com





if [ $STORAGE_OPTION = "y" ]; then
   gcloud iam service-accounts create storage-reader-service-account --project $STORAGE_PROJECT
   gcloud iam service-accounts keys create ./$FOLDER/storage-reader-key.json --iam-account  storage-reader-service-account@$STORAGE_PROJECT.iam.gserviceaccount.com
   gcloud projects add-iam-policy-binding $STORAGE_PROJECT --member="serviceAccount:storage-reader-service-account@$STORAGE_PROJECT.iam.gserviceaccount.com" --role='roles/storage.objectAdmin'
fi
