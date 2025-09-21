#!/usr/bin/env bash
#
# Minimal edits of your original script to:
#  - be safe when sourced (won't kill the calling shell)
#  - still work when executed
#  - handle the 2-key quota by deleting the oldest key and retrying
#  - persist new creds into the default AWS CLI profile
#

USER_NAME="terraform-crypto-etl"

# Detect whether script is being sourced (works in bash and zsh)
if (return 0 2>/dev/null); then
  SOURCED=1
else
  SOURCED=0
fi

# Fatal handler that returns when sourced, exits when executed
fatal() {
  local lineno="${1:-}"
  echo "Error occurred at line ${lineno}. Aborting."
  if [[ $SOURCED -eq 1 ]]; then
    return 1
  else
    exit 1
  fi
}

# If executed (not sourced) enable errexit and trap ERR
if [[ $SOURCED -eq 0 ]]; then
  set -e
  trap 'fatal $LINENO' ERR
fi

echo "Creating new access keys for IAM user: $USER_NAME"

# Try to create a key. If it fails with LimitExceeded, delete oldest key and retry once.
create_key() {
  aws iam create-access-key --user-name "$USER_NAME"
}

CREDS_JSON=$(create_key 2>&1) || {
  if printf '%s' "$CREDS_JSON" | grep -q 'LimitExceeded'; then
    echo "Access key quota reached. Deleting oldest key and retrying..."
    ALL_KEYS_JSON=$(aws iam list-access-keys --user-name "$USER_NAME") || fatal $LINENO
    # pick oldest by CreateDate
    OLDEST_KEY=$(jq -r '.AccessKeyMetadata | sort_by(.CreateDate) | .[0].AccessKeyId' <<< "$ALL_KEYS_JSON")
    if [[ -n "$OLDEST_KEY" && "$OLDEST_KEY" != "null" ]]; then
      aws iam delete-access-key --user-name "$USER_NAME" --access-key-id "$OLDEST_KEY" || fatal $LINENO
      echo "Deleted oldest key: $OLDEST_KEY"
      CREDS_JSON=$(create_key 2>&1) || fatal $LINENO
    else
      echo "No key found to delete. Cannot proceed."
      fatal $LINENO
    fi
  else
    # some other error
    printf '%s\n' "$CREDS_JSON"
    fatal $LINENO
  fi
}

NEW_ACCESS_KEY=$(jq -r '.AccessKey.AccessKeyId' <<< "$CREDS_JSON")
NEW_SECRET_KEY=$(jq -r '.AccessKey.SecretAccessKey' <<< "$CREDS_JSON")

if [[ -z "$NEW_ACCESS_KEY" || -z "$NEW_SECRET_KEY" || "$NEW_ACCESS_KEY" == "null" ]]; then
  echo "Failed to create new access keys."
  fatal $LINENO
fi

echo "New access key created: $NEW_ACCESS_KEY"

# Delete any remaining old keys (all keys except the new one)
ALL_KEYS_JSON=$(aws iam list-access-keys --user-name "$USER_NAME") || fatal $LINENO
for KEY in $(jq -r '.AccessKeyMetadata[].AccessKeyId' <<< "$ALL_KEYS_JSON"); do
  if [[ "$KEY" != "$NEW_ACCESS_KEY" ]]; then
    echo "Deleting old access key: $KEY"
    aws iam delete-access-key --user-name "$USER_NAME" --access-key-id "$KEY" || fatal $LINENO
  fi
done

# Get region (fatal if not present)
AWS_REGION=$(aws configure get region) || true
if [[ -z "$AWS_REGION" ]]; then
  echo "AWS region not found in AWS CLI config. Please run 'aws configure' before this script."
  fatal $LINENO
fi
export AWS_DEFAULT_REGION="$AWS_REGION"
echo "AWS region set to $AWS_REGION"

# Export to current shell (useful when sourced)
export AWS_ACCESS_KEY_ID="$NEW_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$NEW_SECRET_KEY"
echo "AWS credentials set in current shell session - $USER_NAME"

# Persist into default AWS CLI profile so the change survives new terminals
# (Uses 'aws configure set' which edits ~/.aws/credentials and ~/.aws/config)
aws configure set aws_access_key_id "$NEW_ACCESS_KEY" --profile default || fatal $LINENO
aws configure set aws_secret_access_key "$NEW_SECRET_KEY" --profile default || fatal $LINENO
aws configure set region "$AWS_REGION" --profile default || fatal $LINENO
echo "Updated default AWS CLI profile with new credentials."

# Success exit/return depending on how script was invoked
if [[ $SOURCED -eq 0 ]]; then
  exit 0
else
  return 0
fi
