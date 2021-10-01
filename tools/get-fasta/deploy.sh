gcloud functions deploy get_fasta \
    --runtime=python38 \
    --trigger-http \
    --memory=1024MB \
    --source . \
    --env-vars-file .env.yml \
    --stage-bucket psss-team4-victorlin

gcloud functions set-iam-policy get_fasta iam-policy.json
