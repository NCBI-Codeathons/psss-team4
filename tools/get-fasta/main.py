import os
import subprocess
from tempfile import TemporaryDirectory
from google.cloud import storage

bucket_name = os.getenv('BUCKET')
client = storage.Client()
bucket = client.get_bucket(bucket_name)

def get_fasta(request):
    request_json = request.get_json()
    run_accession = request_json['run_accession']
    tmp_dir = TemporaryDirectory()
    subprocess.call(f"./get-fasta.sh {tmp_dir.name} {run_accession}", shell=True, executable='/bin/bash')
    blob = bucket.blob(f'fasta/{run_accession}.fasta')
    blob.upload_from_filename(filename=os.path.join(tmp_dir.name, 'tmp.fasta'))
    return f'Uploaded {bucket_name}/fasta/{run_accession}.fasta'
