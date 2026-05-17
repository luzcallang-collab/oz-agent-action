#!/usr/bin/env bash
set -euo pipefail

USAGE="Usage: $0 [--pattern PATTERN] [--confirm]"
PATTERN=""
CONFIRM=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pattern)
      PATTERN="$2"
      shift 2
      ;;
    --confirm)
      CONFIRM=1
      shift
      ;;
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      echo "$USAGE" >&2
      exit 1
      ;;
  esac
done

if [ -z "$PATTERN" ]; then
  echo "Please pass --pattern with the vendor keyword to remove (e.g. Microsoft)." >&2
  exit 2
fi

TS=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP_DIR="backups/branding-$TS"
mkdir -p "$BACKUP_DIR"

echo "Scanning for files matching pattern: $PATTERN"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  FILES=$(git ls-files | xargs grep -I -l -E "$PATTERN" || true)
else
  FILES=$(grep -I -r -l -E "$PATTERN" . || true)
fi

if [ -z "$FILES" ]; then
  echo "No files matched pattern: $PATTERN"
  exit 0
fi

echo "Found files:"
echo "$FILES"

echo "Backing up matched files to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
while IFS= read -r f; do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp --parents "$f" "$BACKUP_DIR/" 2>/dev/null || cp "$f" "$BACKUP_DIR/$(basename "$f")" || true
  fi
done <<< "$FILES"

echo "Backup complete. No files were removed yet."

if [ "$CONFIRM" -ne 1 ]; then
  echo "Run with --confirm to remove the matched files (non-reversible without backup)." >&2
  exit 0
fi

echo "Removing matched files and creating a git commit"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository; removing files from filesystem." >&2
  while IFS= read -r f; do
    rm -f "$f" || true
  done <<< "$FILES"
  exit 0
fi

git rm -f $(echo "$FILES" | xargs -d '\n' -r echo) || true
git commit -m "chore: remove files matching pattern '$PATTERN' (automated)" || true

echo "Files removed and commit created. Review changes before pushing." 
