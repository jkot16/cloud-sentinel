#!/bin/bash

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/data}"
S3_BUCKET="${S3_BUCKET:-your-bucket-name}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
LOG_GROUP="${LOG_GROUP:-/cloud-sentinel/backup}"
LOG_GROUP="${LOG_GROUP#//}"
LOG_STREAM="${LOG_STREAM:-main-backup-log}"
ENV_PREFIX="${ENV_PREFIX:-PROD}"
AWS_REGION="${AWS_REGION:-eu-central-1}"

# readable name
DATE_TAG=$(date +"%d_%m_%Y____%H-%M")
FILENAME="${ENV_PREFIX}_cloud_backup_${DATE_TAG}.tar.gz"
TMP_FILE="/tmp/${FILENAME}"


# Functions
send_slack() {
  [[ -n "$SLACK_WEBHOOK" ]] && curl -s -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$1\"}" "$SLACK_WEBHOOK" > /dev/null
}

log_cloudwatch() {
  set -euo pipefail

  echo "[DEBUG] Effective AWS Identity:"
  aws sts get-caller-identity || echo "[ERROR] Cannot get caller identity"

  local TIMESTAMP=$(date +%s000)
  local MESSAGE="$1"

  local TOKEN
  TOKEN=$(aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name "$LOG_STREAM" \
    --region "$AWS_REGION" \
    --query "logStreams[0].uploadSequenceToken" \
    --output text 2>/dev/null || echo "")

  echo "[DEBUG] Token: '$TOKEN'"
  echo "[DEBUG] Message: '$MESSAGE'"

  if [[ -z "$TOKEN" || "$TOKEN" == "None" || "$TOKEN" == "null" ]]; then
    aws logs put-log-events \
      --log-group-name "$LOG_GROUP" \
      --log-stream-name "$LOG_STREAM" \
      --region "$AWS_REGION" \
      --log-events timestamp=$TIMESTAMP,message="$MESSAGE"
  else
    aws logs put-log-events \
      --log-group-name "$LOG_GROUP" \
      --log-stream-name "$LOG_STREAM" \
      --region "$AWS_REGION" \
      --log-events timestamp=$TIMESTAMP,message="$MESSAGE" \
      --sequence-token "$TOKEN"
  fi

  echo "[INFO] Log sent to CloudWatch"
}






# Backup process
echo "[INFO] Creating archive from $BACKUP_DIR..."
if tar -czf "$TMP_FILE" "$BACKUP_DIR"; then
  echo "[INFO] Archive created: $TMP_FILE"
else
  MSG="Backup failed – tar error"
  echo "$MSG"; send_slack "$MSG"; log_cloudwatch "$MSG"; exit 1
fi

echo "[INFO] Uploading to S3..."
if aws s3 cp "$TMP_FILE" "s3://$S3_BUCKET/"; then
  MSG="Backup successful: $(basename "$TMP_FILE")"
else
  MSG="Upload failed: $(basename "$TMP_FILE")"
fi

echo "$MSG"
send_slack "$MSG"
log_cloudwatch "$MSG"
