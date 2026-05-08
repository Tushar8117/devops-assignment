#!/bin/bash

# ============================================================
# Log Archival Script
# Archives logs older than 7 days to /mnt/log-archive
# Falls back to local archive if mount not available
# ============================================================

LOG_DIR="/home/ubuntu/devops-assignment/logs"
ARCHIVE_DIR="/mnt/log-archive"
FALLBACK_ARCHIVE_DIR="/home/ubuntu/devops-assignment/log-archive"
SCRIPT_LOG="/home/ubuntu/devops-assignment/logs/archival.log"
DAYS_OLD=7
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ============================================================
# Logging function
# ============================================================
log() {
    echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $1" | tee -a "$SCRIPT_LOG"
}

# ============================================================
# Determine archive destination
# ============================================================
if mountpoint -q "$ARCHIVE_DIR" 2>/dev/null; then
    DEST_DIR="$ARCHIVE_DIR"
    log "INFO  | Using EBS mount at $ARCHIVE_DIR"
else
    DEST_DIR="$FALLBACK_ARCHIVE_DIR"
    log "WARN  | EBS mount not available. Using fallback: $FALLBACK_ARCHIVE_DIR"
fi

mkdir -p "$DEST_DIR"

# ============================================================
# Find logs older than 7 days
# ============================================================
log "INFO  | Scanning $LOG_DIR for files older than $DAYS_OLD days..."

OLD_LOGS=$(find "$LOG_DIR" -maxdepth 1 -type f -name "*.log*" -mtime +$DAYS_OLD)

if [ -z "$OLD_LOGS" ]; then
    log "INFO  | No logs older than $DAYS_OLD days found. Exiting."
    exit 0
fi

# ============================================================
# Compress and archive
# ============================================================
ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="$DEST_DIR/$ARCHIVE_NAME"
TEMP_ARCHIVE="/tmp/$ARCHIVE_NAME"

log "INFO  | Found logs to archive:"
echo "$OLD_LOGS" | while read -r f; do
    log "INFO  |   → $f"
done

# Create compressed archive in /tmp first
tar -czf "$TEMP_ARCHIVE" $OLD_LOGS 2>> "$SCRIPT_LOG"

if [ $? -ne 0 ]; then
    log "ERROR | Failed to create archive. Aborting. Logs NOT deleted."
    rm -f "$TEMP_ARCHIVE"
    exit 1
fi

log "INFO  | Archive created at $TEMP_ARCHIVE"

# ============================================================
# Move archive to destination
# ============================================================
mv "$TEMP_ARCHIVE" "$ARCHIVE_PATH"

if [ $? -ne 0 ]; then
    log "ERROR | Failed to move archive to $DEST_DIR. Logs NOT deleted."
    rm -f "$TEMP_ARCHIVE"
    exit 1
fi

log "INFO  | Archive moved to $ARCHIVE_PATH"

# ============================================================
# Delete original logs ONLY after successful archive
# ============================================================
echo "$OLD_LOGS" | while read -r f; do
    rm -f "$f"
    log "INFO  | Deleted original: $f"
done

log "INFO  | Archival complete. Archive: $ARCHIVE_NAME"
exit 0
