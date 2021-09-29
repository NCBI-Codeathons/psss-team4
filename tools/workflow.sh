# INPUT
genbank="NC_045512"

# intermediate files
genbank_fa="$genbank.fa"
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$genbank&rettype=fasta" > $genbank_fa
makeblastdb -dbtype nucl -in $genbank_fa -out $genbank

# ElasticBLAST
# edit elastic-blast .ini