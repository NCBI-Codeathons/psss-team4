import subprocess
from tempfile import NamedTemporaryFile

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

    try:
        f = NamedTemporaryFile()
        rc = subprocess.call(f"./get-fasta.sh {f.name}", shell=True)
    except Exception as e:
        return str(e)

    return f.read()
