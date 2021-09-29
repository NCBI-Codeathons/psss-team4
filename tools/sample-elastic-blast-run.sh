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

elastic-blast submit --db pdbnt --query gs://elastic-blast-samples/queries/MANE/MANE.GRCh38.v0.8.select_refseq_rna.fna --program blastn --results ${results_bucket} \
    --num-nodes 1 \
    --machine-type n1-standard-32 \
    --num-cpus 2 \
    --mem-limit 1G \
    -- -outfmt '7 std staxids'