#!/usr/bin/env bash
set -e

export AWS_REGION=us-west-2

for group in $(ls -d */); do
    cd $group
    group=$(echo -n $group | tr -d "/")

    status_code=`curl -s -o /dev/null -I -w "%{http_code}" https://${S3_BUCKET_NAME}.s3.us-west-2.amazonaws.com/${group}/index.yaml`
    if [ "$status_code" == "404" ]; then
        helm s3 init s3://$S3_BUCKET_NAME/$group
    fi
    
    helm repo add $group s3://$S3_BUCKET_NAME/$group

    for D in $(ls -d */); do
        helm package --dependency-update $D
    done

    for F in $(ls -f *.tgz); do
        if [ "$GLUEOPS_ENV" == "development" ]; then
            helm s3 push --acl="public-read" --relative $F $group --force
        fi

        if [ "$GLUEOPS_ENV" == "production" ]; then
            helm s3 push --acl="public-read" --relative $F $group --ignore-if-exists
        fi

    done
    cd ..
done
