#!/bin/bash

# call with two variables, example:
# ./workflow.sh NC_024907 gs://pss4-madden/RESULTS/CARIBOU2
# First option is the accession of the sequence for the pebble search
# Second option is the path to your results bucket, which should be empty (or elastic-blast will refuse to 
# overwrite old results)

set -euo pipefail
shopt -s nullglob

##############################################################################
# INPUT
genbank="${1%.fa}"
results_bucket=${2:-"gs://psss-team4/test-results-$USER"}

##############################################################################
# Configuration
# Documentation on results: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#results
export ELB_RESULTS=$results_bucket
export ELB_GCP_PROJECT=codeathon-psss-2021
export ELB_GCP_REGION=us-east4
export ELB_GCP_ZONE=us-east4-a

pebble_search_host=34.139.36.223
blastdb_bucket="gs://psss-team4/DB"


CFG=`mktemp -t $(basename -s .sh $0)-XXXXXXX.ini`
PEBBLES=`mktemp -t $(basename -s .sh $0)-XXXXXXX.out`
trap " /bin/rm -fr $CFG $PEBBLES" INT QUIT EXIT HUP KILL ALRM


# intermediate files
genbank_fa="$genbank.fa"
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$genbank&rettype=fasta" > $genbank_fa

##############################################################################
# Pebble search
/usr/local/bin/psearch_gcp.sh --host $pebble_search_host $genbank_fa > $PEBBLES
num_hits=`wc -l $PEBBLES | cut -f 1 -d ' '`
if [ $num_hits -eq 0 ] ; then
    echo "Pebble search found no hits for $genbank"
    exit 1
fi

##############################################################################
# TODO; filter by some criteria
head $PEBBLES | awk '{print $1}' > sra_hits.txt


##############################################################################
# TODO; Fetch fasta for the SRA hits, 
#EB_QUERIES=FIXME
#EB_QUERIES="/home/madden/CARIBOUFECES/caribou.query-list"
parallel -t \
    curl -s -X POST "https://us-east4-${ELB_GCP_PROJECT}.cloudfunctions.net/get_fasta" -H "Content-Type:application/json" -d '{"run_accession": "{}"}' -o {}.fsa

##############################################################################
#use the pebblesearch query as ElasticBLAST target database

target_blastdb="$genbank"
makeblastdb -dbtype nucl -in $genbank_fa -out $target_blastdb -parse_seqids
gsutil -qm cp $target_blastdb.* ${blastdb_bucket}


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
# possbily best not to change.
#num-cpus = FIXME

[blast]
# See documentation for setting batch-length at https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#batch-length
# Setting batch-len to a billion seems to work well for very small databases and large query sets
batch-len = 1000000000
# See documentation for supported programs: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#blast-program
program = blastn
# See documentation for using your own BLASTDB:
# https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#blast-database
# https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/tutorials/create-blastdb-metadata.html?highlight=create
db = ${blastdb_bucket}/$target_blastdb
# See documentation for supported formats: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#query-sequence-data
queries = $EB_QUERIES
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#memory-limit-for-blast-search 
#mem-limit = FIXME
# Documentation: https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/configuration.html#blast-options
options = -evalue 0.0001 -outfmt 7 -mt_mode 1
EOF

elastic-blast submit --cfg $CFG
elastic-blast status
