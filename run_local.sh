#!/bin/bash

# Exit immediately if any command fails
set -e

echo "=== VaultTask: Starting Local Environment ==="

# 1. Initialize/Migrate Local D1 Database Schema
echo "[1/3] Setting up local database schema..."
cd cloudflare_backend
npx wrangler d1 execute vaulttask-db --local --file=d1_schema.sql -y
cd ..

# 2. Start Cloudflare Worker (Backend) in the background
echo "[2/3] Starting backend worker locally (Miniflare)..."

# Kill any stale wrangler/miniflare processes from previous runs
echo "Cleaning up stale wrangler processes..."
pkill -f "wrangler dev" 2>/dev/null || true
pkill -f "miniflare" 2>/dev/null || true
sleep 1

cd cloudflare_backend

# Free up ports 8787, 8788, 8789 to avoid port collisions
for port in 8787 8788 8789; do
  STALE_PID=$(lsof -t -i:$port 2>/dev/null || /usr/bin/lsof -t -i:$port 2>/dev/null || true)
  if [ ! -z "$STALE_PID" ]; then
    echo "Found conflicting process $STALE_PID on port $port. Freeing up port..."
    kill -9 $STALE_PID 2>/dev/null || true
  fi
done
sleep 1

# Generate local secret variables dynamically
echo "DEEPGRAM_API_KEY=\"5ad0ebfddedec0b349c567dc7625bef97ad6f3a2\"" > .dev.vars
echo "OPENROUTER_API_KEY=\"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\"" >> .dev.vars

npx wrangler dev --port 8787 &
BACKEND_PID=$!
cd ..

# Function to clean up background processes on exit
cleanup() {
  echo ""
  echo "=== Stopping local backend and cleaning up... ==="
  kill $BACKEND_PID 2>/dev/null || true
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# Wait a couple of seconds for backend to start
sleep 3

# 3. Start Flutter Frontend Web on Chrome
echo "[3/3] Starting Flutter application on Chrome..."
cd my_ai_assistant
flutter run -d web-server --web-port=8080
