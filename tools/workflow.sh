# INPUT
genbank="${1%.fa}"

# intermediate files
genbank_fa="$genbank.fa"
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$genbank&rettype=fasta" > $genbank_fa
makeblastdb -dbtype nucl -in $genbank_fa -out $genbank

# ElasticBLAST
# edit elastic-blast .ini
elastic-blast submit --cfg elastic-blast.ini --loglevel # wait for return
