#!/bin/bash

set -euo pipefail
shopt -s nullglob

##############################################################################
# INPUT
genbank="${1%.fa}"

##############################################################################
# Configuration
# Documentation on results: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#results
results_bucket=${1:-"gs://psss-team4/test-results-$USER"}
export ELB_RESULTS=$results_bucket

pebble_search_host=34.139.36.223
blastdb_bucket=gs://psss-team4


CFG=`mktemp -t $(basename -s .sh $0)-XXXXXXX.ini`
PEBBLES=`mktemp -t $(basename -s .sh $0)-XXXXXXX.out`
trap " /bin/rm -fr $CFG $PEBBLES" INT QUIT EXIT HUP KILL ALRM


# intermediate files
genbank_fa="$genbank.fa"
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$genbank&rettype=fasta" > $genbank_fa

##############################################################################
# Pebble search
/usr/local/bin/psearch_gcp --host $pebble_search_host $genbank_fa > $PEBBLES
num_hits=`wc -l $PEBBLES | cut -f 1 -d ' '`
if [ $num_hits -eq 0 ] ; then
    echo "Pebble search found no hits for $genbank"
    exit 1
fi

##############################################################################
# TODO; filter by some criteria
head $PEBBLES | awk '{print $1}' > sra_hits.txt


##############################################################################
# TODO; Fetch fasta for the SRA hits, use these as ElasticBLAST target database

makeblastdb -dbtype nucl -in $sra_hits_fa -out $target_blastdb
gsutil -qm cp $target_blastdb.* gs://${blastdb_bucket}/$target_blastdb


##############################################################################
# ElasticBLAST
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
num-nodes = 10
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#number-of-cpus
num-cpus = FIXME

[blast]
# See documentation for supported programs: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#blast-program
program = blastn
# See documentation for using your own BLASTDB:
# https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#blast-database
# https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/tutorials/create-blastdb-metadata.html?highlight=create
db = gs://${BLASTDB_BUCKET}/$target_blastdb
# See documentation for supported formats: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#query-sequence-data
queries = FIXME
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#memory-limit-for-blast-search 
mem-limit = FIXME
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#blast-options
options = -outfmt '7 std staxids'
EOF

elastic-blast submit --cfg $CFG
elastic-blast status
