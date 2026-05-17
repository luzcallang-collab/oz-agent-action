#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
REPORT_DIR="reports"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
REPORT_FILE="$REPORT_DIR/branding-report-$TIMESTAMP.md"
mkdir -p "$REPORT_DIR"

echo "# Branding scan report - $TIMESTAMP" > "$REPORT_FILE"
echo "Scanned path: $ROOT_DIR" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

PATTERNS=("Microsoft" "Apache" "Linux" "Akamai" "Cloudflare" "Insider" "Azure" "Google" "Amazon" "aws")

echo "Searching for the following patterns:" >> "$REPORT_FILE"
for p in "${PATTERNS[@]}"; do
  echo "- $p" >> "$REPORT_FILE"
done
echo "" >> "$REPORT_FILE"

echo "Files with matches:" >> "$REPORT_FILE"

# Use git to limit to tracked files when possible
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  FILES=$(git ls-files)
else
  FILES=$(find "$ROOT_DIR" -type f ! -path "./.git/*")
fi

MATCH_FOUND=0
while IFS= read -r f; do
  if [ ! -f "$f" ]; then
    continue
  fi
  if grep -I -n -E "$(printf "%s|" "${PATTERNS[@]}" | sed 's/|$//')" "$f" >/dev/null 2>&1; then
    MATCH_FOUND=1
    echo "- $f" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    grep -I -n -E "$(printf "%s|" "${PATTERNS[@]}" | sed 's/|$//')" "$f" | sed -n '1,200p' >> "$REPORT_FILE" || true
    echo '```' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
  fi
done <<< "$FILES"

if [ "$MATCH_FOUND" -eq 0 ]; then
  echo "No matches found." >> "$REPORT_FILE"
fi

echo "Report generated at: $REPORT_FILE"
