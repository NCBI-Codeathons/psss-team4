#!/bin/bash
# sample-elastic-blast-run.sh: Sample script to run ElasticBLAST
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)
# Created: Tue 28 Sep 2021 05:10:14 PM EDT

set -euo pipefail
shopt -s nullglob

# Documentation on results: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#results
results_bucket=${1:-"gs://psss-team4/test-results-$USER"}

export ELB_GCP_PROJECT=codeathon-psss-2021
export ELB_GCP_REGION=us-east4
export ELB_GCP_ZONE=us-east4-c
export ELB_LOGLEVEL=DEBUG
export ELB_DISABLE_AUTO_SHUTDOWN=1

elastic-blast --version

CFG=`mktemp -t $(basename -s .sh $0)-XXXXXXX`
trap " /bin/rm -fr $CFG " INT QUIT EXIT HUP KILL ALRM

cat >$CFG <<EOF
[cloud-provider]
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#gcp-project
gcp-project = $ELB_GCP_PROJECT
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#gcp-region
gcp-region = $ELB_GCP_REGION
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#gcp-zone
gcp-zone = $ELB_GCP_ZONE

# These two settings are needed because the GCP project doesn't have a 'default' network
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#gcp-network
gcp-network = research
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#gcp-sub-network
gcp-subnetwork = subnet-us-east4

[cluster]
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#machine-type
machine-type = n1-standard-32
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#number-of-worker-nodes
num-nodes = 1
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#number-of-cpus
num-cpus = 2

[blast]
# See documentation for supported programs: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#blast-program
program = blastn
# See documentation for using your own BLASTDB:
# https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#blast-database
# https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/tutorials/create-blastdb-metadata.html?highlight=create
db = pdbnt
# See documentation for supported formats: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#query-sequence-data
queries = gs://elastic-blast-samples/queries/MANE/MANE.GRCh38.v0.8.select_refseq_rna.fna
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#memory-limit-for-blast-search 
mem-limit = 1G
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#blast-options
options = -outfmt '7 std staxids'
EOF

elastic-blast submit --cfg $CFG --results ${results_bucket}
elastic-blast status --results ${results_bucket}
