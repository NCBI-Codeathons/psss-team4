import os
import subprocess
from tempfile import TemporaryDirectory

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
    try:
        tmp_dir = TemporaryDirectory()
        subprocess.call(f"./get-fasta.sh {tmp_dir.name} {'ERR164407'}", shell=True, executable='/bin/bash')
    except Exception as e:
        return str(e)

    with open(os.path.join(tmp_dir.name, "output.txt")) as f:
        return f.read()
