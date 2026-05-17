#!/usr/bin/env bash
set -euo pipefail

echo "== Auto-fix started: $(date -u) =="

# Install dependencies
if [ -f package.json ]; then
  echo "Installing npm dependencies..."
  npm install

  echo "Running npm audit fix..."
  npm audit fix || true

  echo "Updating direct dependencies..."
  npm update || true

  echo "Formatting code..."
  npm run format:write || true

  echo "Running eslint --fix..."
  if npm run lint --silent -- --fix; then
    echo "Lint fixer ran"
  fi

  echo "Building project..."
  npm run build || true
fi

# Rebuild containers if Dockerfile or docker-compose present
if [ -f Dockerfile ]; then
  echo "Dockerfile found — building image..."
  if command -v docker >/dev/null 2>&1; then
    docker build -t auto-fix-image:latest . || true
  else
    echo "docker not available; skipping build"
  fi
fi

if [ -f docker-compose.yml ] || [ -f docker-compose.yaml ]; then
  echo "docker-compose file found — rebuilding services..."
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose build || true
  elif command -v docker >/dev/null 2>&1; then
    docker compose build || true
  else
    echo "docker-compose not available; skipping compose build"
  fi
fi

# Commit & push changes if running in CI with token
BRANCH="auto-fix/$(date -u +%Y%m%d%H%M%S)"
if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"
  git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  git checkout -b "$BRANCH"
  git add -A
  if git diff --staged --quiet; then
    echo "No changes to commit"
  else
    git commit -m "chore: automatic fixes and rebuilds"
    git push -u origin "$BRANCH"
    if command -v gh >/dev/null 2>&1; then
      gh pr create --title "chore: automatic fixes" --body "Automated fixes and rebuilds." --base main --head "$BRANCH" || true
    fi
  fi
else
  echo "GITHUB_TOKEN or GITHUB_REPOSITORY not set — skipping push/PR creation"
fi

echo "== Auto-fix finished: $(date -u) =="
