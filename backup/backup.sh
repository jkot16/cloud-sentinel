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
  local TIMESTAMP=$(date +%s000)
  local MESSAGE="$1"

  TOKEN=$(aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name-prefix "$LOG_STREAM" \
    --query "logStreams[0].uploadSequenceToken" \
    --output text 2>/dev/null)

  LOG_ENTRY="[{\"timestamp\":$TIMESTAMP,\"message\":\"$MESSAGE\"}]"

  if [ "$TOKEN" == "None" ] || [ -z "$TOKEN" ]; then
    aws logs put-log-events \
      --log-group-name "$LOG_GROUP" \
      --log-stream-name "$LOG_STREAM" \
      --log-events "$LOG_ENTRY" \
      --region eu-central-1
  else
    aws logs put-log-events \
      --log-group-name "$LOG_GROUP" \
      --log-stream-name "$LOG_STREAM" \
      --log-events "$LOG_ENTRY" \
      --sequence-token "$TOKEN" \
      --region eu-central-1
  fi
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
