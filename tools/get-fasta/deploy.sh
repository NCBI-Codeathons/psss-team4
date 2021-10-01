function_name="get_fasta"
region="us-east4"

gcloud functions deploy $function_name \
    --runtime=python38 \
    --trigger-http \
    --memory=1024MB \
    --source . \
    --env-vars-file .env.yml \
    --region $region

gcloud functions set-iam-policy $function_name --region $region iam-policy.json
