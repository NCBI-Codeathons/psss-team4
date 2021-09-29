#!/bin/bash -xe
# initial-setup.sh: Script to set up cloud resources for PSSS team4
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)
# Created: Tue 28 Sep 2021 04:31:36 PM EDT

set -euo pipefail
shopt -s nullglob

bucket=${1:-"gs://psss-team4"}
instance_name=${2:-"psss-team4"}

region=us-east4
zone=us-east4-c

gsutil ls ${bucket} >& /dev/null || gsutil mb -c standard -l ${region} ${bucket}

gcloud compute instances create ${instance_name} --project=codeathon-psss-2021 --zone=${zone} --machine-type=e2-standard-32 --network-interface=network-tier=PREMIUM,subnet=subnet-us-east4 --maintenance-policy=MIGRATE --service-account=281282530694-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=https-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/ubuntu-os-cloud/global/images/ubuntu-1804-bionic-v20210918,mode=rw,size=1000,type=projects/codeathon-psss-2021/zones/us-east4-c/diskTypes/pd-ssd --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any


gcloud compute ssh ${instance_name} --zone ${zone} -- sudo apt-get -yqm update
gcloud compute ssh ${instance_name} --zone ${zone} -- sudo apt-get upgrade python3.8
gcloud compute ssh ${instance_name} --zone ${zone} -- sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
gcloud compute ssh ${instance_name} --zone ${zone} -- sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2

gcloud compute ssh ${instance_name} --zone ${zone} -- curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
gcloud compute ssh ${instance_name} --zone ${zone} -- sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# FIXME: the version of BLAST+ is very old (2.6.0) - needs to be updated
gcloud compute ssh ${instance_name} --zone ${zone} -- sudo apt-get install -yq python3-distutils python3-pip ncbi-blast+

gcloud compute ssh ${instance_name} --zone ${zone} -- sudo pip3 install elastic-blast
