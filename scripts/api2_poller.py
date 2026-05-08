#!/usr/bin/env python3

import urllib.request
import json
from datetime import datetime, timezone
import os
import glob

LOG_DIR = "/home/ubuntu/devops-assignment/logs"
LOG_FILE = os.path.join(LOG_DIR, "api2.log")
MAX_LOG_SIZE_BYTES = 1 * 1024 * 1024  # 1MB
MAX_LOG_FILES = 5

def rotate_logs():
    """Rotate log file if it exceeds max size."""
    if not os.path.exists(LOG_FILE):
        return

    if os.path.getsize(LOG_FILE) < MAX_LOG_SIZE_BYTES:
        return

    # Shift old logs: api2.log.4 → delete, api2.log.3 → api2.log.4 ...
    for i in range(MAX_LOG_FILES - 1, 0, -1):
        old = f"{LOG_FILE}.{i}"
        new = f"{LOG_FILE}.{i + 1}"
        if os.path.exists(old):
            if i + 1 >= MAX_LOG_FILES:
                os.remove(old)
            else:
                os.rename(old, new)

    # Rename current log to .1
    os.rename(LOG_FILE, f"{LOG_FILE}.1")
    print(f"[{datetime.now(timezone.utc).isoformat()}] Log rotated.")

def call_api2():
    """Call /api2 endpoint and return response."""
    try:
        url = "http://127.0.0.1:8000/api2"
        with urllib.request.urlopen(url, timeout=10) as response:
            data = json.loads(response.read().decode())
            return {"success": True, "data": data}
    except Exception as e:
        return {"success": False, "error": str(e)}

def write_log(entry):
    """Write log entry to file."""
    os.makedirs(LOG_DIR, exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(entry + "\n")

def main():
    timestamp = datetime.now(timezone.utc).isoformat()
    result = call_api2()

    if result["success"]:
        log_entry = f"[{timestamp}] SUCCESS | Response: {json.dumps(result['data'])}"
    else:
        log_entry = f"[{timestamp}] FAILED  | Error: {result['error']}"

    rotate_logs()
    write_log(log_entry)
    print(log_entry)

if __name__ == "__main__":
    main()
