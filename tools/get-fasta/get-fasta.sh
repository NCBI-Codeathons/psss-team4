#!/bin/bash
tmp_dir=$1
run_accession=$2

cd $tmp_dir
# https://ena-docs.readthedocs.io/en/latest/retrieval/file-download/sra-ftp-structure.html
wget -O "tmp.fastq.gz" "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/${run_accession:0:6}/$run_accession/$run_accession.fastq.gz"
gunzip "tmp.fastq.gz"
# https://stackoverflow.com/a/10359425
sed -n '1~4s/^@/>/p;2~4p' "tmp.fastq" > "tmp.fasta"
