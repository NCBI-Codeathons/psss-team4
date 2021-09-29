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

gcloud compute instances create ${instance_name} --project=codeathon-psss-2021 --zone=${zone} --machine-type=e2-standard-32 \
    --network-interface=network-tier=PREMIUM,subnet=subnet-us-east4 --maintenance-policy=MIGRATE \
    --service-account=281282530694-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/cloud-platform --tags=https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/ubuntu-os-cloud/global/images/ubuntu-1804-bionic-v20210928,mode=rw,size=1000,type=projects/codeathon-psss-2021/zones/${zone}/diskTypes/pd-ssd \
    --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
sleep 15


SETUP_SCRIPT=`mktemp -t $(basename -s .sh $0)-XXXXXXX`
trap " /bin/rm -fr $SETUP_SCRIPT " INT QUIT EXIT HUP KILL ALRM

cat > $SETUP_SCRIPT <<-EOF
#!/bin/bash -xe
apt-get -yqm update
apt-get -yq upgrade python3.8
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

curl -s "https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/`curl -L -s https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/VERSION`/ncbi-blast-`curl -L -s https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/VERSION`+-x64-linux.tar.gz" -o ncbi-blast.tar.gz
tar -zxvf ncbi-blast.tar.gz -C /usr/local --strip-components 1 --wildcards '*/bin/*'
rm -f ncbi-blast.tar.gz kubectl

apt-get install -yq python3-distutils python3-pip
pip3 install elastic-blast
EOF
cat -n $SETUP_SCRIPT

gcloud compute scp $SETUP_SCRIPT ${instance_name}:/tmp/setup-script.sh --zone ${zone}
gcloud compute ssh ${instance_name} --zone ${zone} -- 'chmod +x /tmp/setup-script.sh && sudo /tmp/setup-script.sh'
