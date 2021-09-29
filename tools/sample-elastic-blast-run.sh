#!/bin/bash
# sample-elastic-blast-run.sh: Sample script to run ElasticBLAST
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)
# Created: Tue 28 Sep 2021 05:10:14 PM EDT

set -euo pipefail
shopt -s nullglob

results_bucket=${1:-"gs://psss-team4/test-results-$USER"}
export ELB_GCP_PROJECT=codeathon-psss-2021
export ELB_GCP_REGION=us-east4
export ELB_GCP_ZONE=us-east4-c
export ELB_LOGLEVEL=DEBUG

elastic-blast --version

CFG=`mktemp -t $(basename -s .sh $0)-XXXXXXX`
trap " /bin/rm -fr $CFG " INT QUIT EXIT HUP KILL ALRM

cat >$CFG <<EOF
[cloud-provider]
gcp-project = $ELB_GCP_PROJECT
gcp-region = $ELB_GCP_REGION
gcp-zone = $ELB_GCP_ZONE
gcp-network = research
gcp-subnetwork = subnet-us-east4

[cluster]
machine-type = n1-standard-32
num-nodes = 1
num-cpus = 2

[blast]
program = blastn
db = pdbnt
queries = gs://elastic-blast-samples/queries/MANE/MANE.GRCh38.v0.8.select_refseq_rna.fna
mem-limit = 1G
options = -outfmt '7 std staxids'
EOF

elastic-blast submit --cfg $CFG --results ${results_bucket}
elastic-blast status --results ${results_bucket}
