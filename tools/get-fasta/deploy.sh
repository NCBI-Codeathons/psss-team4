#!/bin/bash
# Deploys the Cloud Function contained in this directory
region=${1:-"us-east4"}
function_name="get_fasta"

gcloud functions deploy $function_name \
    --runtime=python38 \
    --trigger-http \
    --memory=1024MB \
    --source . \
    --env-vars-file .env.yml \
    --region $region

gcloud functions set-iam-policy $function_name --region $region iam-policy.json
