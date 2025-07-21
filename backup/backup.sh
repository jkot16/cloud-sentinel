#!/bin/bash

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/data}"
S3_BUCKET="${S3_BUCKET:-your-bucket-name}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
LOG_GROUP="${LOG_GROUP:-/cloud-sentinel/backup}"
TMP_FILE="/tmp/data_$(date +"%Y-%m-%dT%H-%M-%S").tar.gz"
LOG_STREAM="$(date +"%Y-%m-%dT%H-%M-%S")"

# Functions
send_slack() {
  [[ -n "$SLACK_WEBHOOK" ]] && curl -s -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$1\"}" "$SLACK_WEBHOOK" > /dev/null
}

log_cloudwatch() {
  aws logs create-log-stream --log-group-name "$LOG_GROUP" --log-stream-name "$LOG_STREAM" 2>/dev/null || true
  aws logs put-log-events \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name "$LOG_STREAM" \
    --log-events timestamp=$(date +%s000),message="$1"
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
