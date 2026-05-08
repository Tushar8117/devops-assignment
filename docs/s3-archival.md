# S3 Log Archival — Documentation

## Why EBS is used instead of S3

AWS S3 access is restricted in the current environment due to network/policy constraints.
Logs are archived to a dedicated directory at `/mnt/log-archive` (EBS volume) or fallback
at `/home/ubuntu/devops-assignment/log-archive`.

S3 integration steps are documented below for environments where S3 access is available.

## S3 Archival Script (Reference)

```bash
#!/bin/bash

LOG_DIR="/home/ubuntu/devops-assignment/logs"
S3_BUCKET="s3://devops-assessment-logs/archives"
SCRIPT_LOG="/home/ubuntu/devops-assignment/logs/archival.log"
DAYS_OLD=7
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

log() {
    echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $1" | tee -a "$SCRIPT_LOG"
}

OLD_LOGS=$(find "$LOG_DIR" -maxdepth 1 -type f -name "*.log*" -mtime +$DAYS_OLD)

if [ -z "$OLD_LOGS" ]; then
    log "INFO | No logs older than $DAYS_OLD days found."
    exit 0
fi

ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"
TEMP_ARCHIVE="/tmp/$ARCHIVE_NAME"

tar -czf "$TEMP_ARCHIVE" $OLD_LOGS
if [ $? -ne 0 ]; then
    log "ERROR | Compression failed. Logs NOT deleted."
    exit 1
fi

# Upload to S3
aws s3 cp "$TEMP_ARCHIVE" "$S3_BUCKET/$ARCHIVE_NAME"

if [ $? -eq 0 ]; then
    log "INFO | Upload successful: $ARCHIVE_NAME"
    echo "$OLD_LOGS" | while read -r f; do
        rm -f "$f"
        log "INFO | Deleted: $f"
    done
    rm -f "$TEMP_ARCHIVE"
else
    log "ERROR | S3 upload failed. Logs NOT deleted."
    rm -f "$TEMP_ARCHIVE"
    exit 1
fi
```

## IAM Requirements
- Attach IAM role to EC2 with `s3:PutObject` permission on the target bucket
- No hardcoded credentials needed with instance role

## Cron Schedule

0 2 * * * /bin/bash /home/ubuntu/devops-assignment/scripts/log_archival.sh
