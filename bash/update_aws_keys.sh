#!/bin/bash

# This script will create new keys for user: terraform-crypto-etl,
# upload them to AWS, and destroy any old keys

set -e  # Exit immediately on any error

# Error handler function
error_handler() {
  echo "Error occurred at line $1. Exiting script."
  exit 1
}

trap 'error_handler $LINENO' ERR

USER_NAME="terraform-crypto-etl"

echo "Creating new access keys for IAM user: $USER_NAME"
CREDS_JSON=$(aws iam create-access-key --user-name "$USER_NAME")

NEW_ACCESS_KEY=$(jq -r '.AccessKey.AccessKeyId' <<< "$CREDS_JSON")
NEW_SECRET_KEY=$(jq -r '.AccessKey.SecretAccessKey' <<< "$CREDS_JSON")

# Avoid deleteing the old keys if creating more has failed
if [[ -z "$NEW_ACCESS_KEY" || -z "$NEW_SECRET_KEY" ]]; then
  echo "Failed to create new access keys. Exiting."
  exit 1
fi

echo "New access key created: $NEW_ACCESS_KEY"

ALL_KEYS_JSON=$(aws iam list-access-keys --user-name "$USER_NAME")
ALL_ACCESS_KEYS=$(jq -r '.AccessKeyMetadata[].AccessKeyId' <<< "$ALL_KEYS_JSON")

for KEY in $ALL_ACCESS_KEYS; do
  if [[ "$KEY" != "$NEW_ACCESS_KEY" ]]; then
    echo "Deleting old access key: $KEY"
    aws iam delete-access-key --user-name "$USER_NAME" --access-key-id "$KEY"
  fi
done

# Dynamically fetch and export AWS region
AWS_REGION=$(aws configure get region)
if [[ -z "$AWS_REGION" ]]; then
  echo "AWS region not found in AWS CLI config. Please configure it first."
  exit 1
fi
export AWS_DEFAULT_REGION="$AWS_REGION"
echo "AWS region set to $AWS_REGION"

export AWS_ACCESS_KEY_ID="$NEW_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$NEW_SECRET_KEY"

echo "AWS credentials set in current shell session."
