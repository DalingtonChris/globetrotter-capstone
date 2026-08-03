#!/usr/bin/env bash
# Pulls the latest backend code, reinstalls deps, and restarts the pm2 process.
# Run from anywhere: /root/find-your-way/backend/update.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Pulling latest changes"
git pull

echo "==> Installing dependencies"
npm install --omit=dev

echo "==> Restarting pm2 process"
pm2 restart find-your-way-api

echo "==> Done"
pm2 status find-your-way-api
