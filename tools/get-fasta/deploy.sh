gcloud functions deploy get_fasta \
    --runtime=python38 \
    --trigger-http \
    --memory=1024MB \
    --source . \
    --stage-bucket psss-team4-victorlin
