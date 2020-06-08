#!/bin/bash


#start the interactive portion to capture user details
echo "This script will help you perform the steps outlined at
https://cloud.google.com/gke-on-prem/docs/how-to/service-accounts
You will be provided the option to create a storage reader service account as well.

Enter the name of the email of your whitelisted service account"
read -p "(example: whitelisted@my-anthos-project.iam.gserviceaccount.com):" WL_SA_EMAIL
read -p "Create storage reader account? (y/n)" STORAGE_OPTION
if [ $STORAGE_OPTION = "y" ]; then
    read -p "Provide Project where GCS Bucket Lives:" STORAGE_PROJECT
fi


#log in to gcloud
gcloud init

#capture the project the user selected during log in
PROJECT=$(gcloud config list --format 'value(core.project)')

#create the folder for the keys and set the variable
FOLDER=$(dirname "$0")/gcp_keys
mkdir -p -m 700 "$FOLDER"
echo ""
echo "The service account key files will live in $FOLDER/"

#create the needed service accounts
gcloud iam service-accounts create register-service-account --project $PROJECT
gcloud iam service-accounts create connect-service-account --project $PROJECT
gcloud iam service-accounts create stackdriver-service-account --project $PROJECT

#create the needed keys
gcloud iam service-accounts keys create "$FOLDER"/register-key.json --iam-account  register-service-account@$PROJECT.iam.gserviceaccount.com
gcloud iam service-accounts keys create "$FOLDER"/connect-key.json --iam-account  connect-service-account@$PROJECT.iam.gserviceaccount.com
gcloud iam service-accounts keys create "$FOLDER"/stackdriver-key.json --iam-account  stackdriver-service-account@$PROJECT.iam.gserviceaccount.com
gcloud iam service-accounts keys create "$FOLDER"/whitelisted-key.json --iam-account  $WL_SA_EMAIL

#assign the needed IAM roles
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:connect-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/gkehub.connect'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:register-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/gkehub.admin'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:register-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/serviceusage.serviceUsageViewer'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:stackdriver-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/stackdriver.resourceMetadata.writer'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:stackdriver-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/logging.logWriter'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:stackdriver-service-account@$PROJECT.iam.gserviceaccount.com" --role='roles/monitoring.metricWriter'
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:$WL_SA_EMAIL" --role="roles/serviceusage.serviceUsageViewer"
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:$WL_SA_EMAIL" --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:$WL_SA_EMAIL" --role="roles/iam.roleViewer"



#enable the required APIs for the project
gcloud services enable --project $PROJECT \
    cloudresourcemanager.googleapis.com \
    container.googleapis.com \
    gkeconnect.googleapis.com \
    gkehub.googleapis.com \
    serviceusage.googleapis.com \
    stackdriver.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com  \
    anthosgke.googleapis.com




#if selected, create the storage reader service account, key, and role binding
if [ $STORAGE_OPTION = "y" ]; then
   gcloud iam service-accounts create storage-reader-service-account --project $STORAGE_PROJECT
   gcloud iam service-accounts keys create "$FOLDER"/storage-reader-key.json --iam-account  storage-reader-service-account@$STORAGE_PROJECT.iam.gserviceaccount.com
   gcloud projects add-iam-policy-binding $STORAGE_PROJECT --member="serviceAccount:storage-reader-service-account@$STORAGE_PROJECT.iam.gserviceaccount.com" --role='roles/storage.objectAdmin'
fi
