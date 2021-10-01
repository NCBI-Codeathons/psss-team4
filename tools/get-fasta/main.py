import os
import subprocess
from tempfile import TemporaryDirectory
from google.cloud import storage

client = storage.Client()

def get_fasta(request):
    request_json = request.get_json()
    run_accession = request_json['run_accession']
    bucket_name = request_json['upload_bucket']
    upload_prefix = request_json['upload_prefix']
    bucket = client.get_bucket(bucket_name)
    tmp_dir = TemporaryDirectory()
    subprocess.call(f"./get-fasta.sh {tmp_dir.name} {run_accession}", shell=True, executable='/bin/bash')
    fasta_file = '{run_accession}.fasta'
    blob = bucket.blob(f'{upload_prefix}{fasta_file}')
    blob.upload_from_filename(filename=os.path.join(tmp_dir.name, 'tmp.fasta'))
    return f'gs://{bucket_name}/{upload_prefix}{fasta_file}'
