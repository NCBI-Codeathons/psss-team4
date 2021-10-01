import os
import subprocess
from tempfile import TemporaryDirectory
from google.cloud import storage

bucket_name = 'psss-team4-victorlin'
client = storage.Client()
bucket = client.get_bucket(bucket_name)

def get_fasta(request):
    """Responds to any HTTP request.
    Args:
        request (flask.Request): HTTP request object.
    Returns:
        The response text or any set of values that can be turned into a
        Response object using
        `make_response <https://flask.palletsprojects.com/en/1.1.x/api/#flask.Flask.make_response>`.
    """
    request_json = request.get_json()

    # request_json['run_accession']
    run_accession = 'ERR164407'
    try:
        tmp_dir = TemporaryDirectory()
        subprocess.call(f"./get-fasta.sh {tmp_dir.name} {run_accession}", shell=True, executable='/bin/bash')
    except Exception as e:
        return str(e)

    blob = bucket.blob(f'fasta/{run_accession}.fasta')
    blob.upload_from_filename(filename=os.path.join(tmp_dir.name, 'tmp.fasta'))
    return f'Uploaded {bucket_name}/fasta/{run_accession}.fasta'
