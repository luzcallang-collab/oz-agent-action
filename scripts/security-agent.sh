#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-/var/log/security-agent}"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/security-agent.log"

echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") Starting security-agent" >> "$LOGFILE"

INTERVAL="${INTERVAL:-300}"
# main loop: collect safe, read-only system information periodically
while true; do
  echo "=== $(date -u) ===" >> "$LOGFILE"

  if command -v journalctl >/dev/null 2>&1; then
    echo "--- journalctl recent ---" >> "$LOGFILE"
    journalctl -n 100 --no-pager >> "$LOGFILE" 2>&1 || true
  fi

  if command -v log >/dev/null 2>&1; then
    echo "--- macOS log show (last 1h) ---" >> "$LOGFILE"
    log show --style syslog --last 1h >> "$LOGFILE" 2>&1 || true
  fi

  if command -v lsusb >/dev/null 2>&1; then
    echo "--- lsusb ---" >> "$LOGFILE"
    lsusb >> "$LOGFILE" 2>&1 || true
  elif command -v system_profiler >/dev/null 2>&1; then
    echo "--- system_profiler SPUSBDataType ---" >> "$LOGFILE"
    system_profiler SPUSBDataType >> "$LOGFILE" 2>&1 || true
  fi

  echo "--- df -h ---" >> "$LOGFILE"
  df -h >> "$LOGFILE" 2>&1 || true

  sleep "$INTERVAL"
done
