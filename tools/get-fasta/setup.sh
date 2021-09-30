mkdir bin
curl -sO https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
tar -zxvf sratoolkit.current-ubuntu64.tar.gz -C bin --strip-components 1
rm sratoolkit.current-ubuntu64.tar.gz
mkdir ~/.ncbi/
cp user-settings.mkfg ~/.ncbi/
