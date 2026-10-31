#!/bin/bash
# ==============================================================================
# MonkeyPR — All-In-One Unified Local Runner
# Starts both the FastAPI Backend (port 8000) and Next.js Frontend (port 3000)
# ==============================================================================

set -e

# Always resolve and change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================================"
echo "🐒 Starting MonkeyPR — Chaos Lab & Autonomous Red-Team Engine"
echo "📂 Working directory: $SCRIPT_DIR"
echo "============================================================"

# 1. Kill any stale processes on 8000 or 3000
for PORT in 8000 3000; do
  PID=$(lsof -ti :$PORT 2>/dev/null || true)
  if [ -n "$PID" ]; then
    echo "⚠️ Port $PORT is occupied by PID $PID. Freeing port..."
    kill -9 $PID 2>/dev/null || true
  fi
done

# 2. Check and activate virtual environment
if [ ! -d ".venv" ]; then
  echo "📦 Creating virtual environment..."
  python3 -m venv .venv
fi

# Ensure dependencies
echo "🔍 Checking Python backend dependencies..."
if [ -f ".venv/bin/uvicorn" ]; then
  echo "✅ Backend dependencies already installed."
else
  echo "⬇️ Installing backend requirements..."
  .venv/bin/python -m pip install -r backend/requirements.txt
fi

# 3. Start Backend in background
echo "🚀 Starting FastAPI Backend on http://127.0.0.1:8000 ..."
.venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

# Trap Ctrl+C to cleanly kill both processes on exit
cleanup() {
  echo ""
  echo "🛑 Shutting down MonkeyPR servers..."
  kill $BACKEND_PID 2>/dev/null || true
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# 4. Wait for backend to be ready
echo "⏳ Waiting for backend API to initialize..."
for i in {1..15}; do
  if curl -s http://127.0.0.1:8000/api/chaos/rules > /dev/null 2>&1; then
    echo "✅ Backend is healthy and responding on http://127.0.0.1:8000"
    break
  fi
  sleep 0.5
done

# 5. Start Frontend
echo "🚀 Starting Next.js Frontend on http://localhost:3000 ..."
echo ""
echo "============================================================"
echo "🎉 MonkeyPR is RUNNING!"
echo "👉 Open Dashboard: http://localhost:3000/chaos-lab"
echo "👉 Backend API Docs: http://localhost:8000/docs"
echo "============================================================"
echo "Press Ctrl+C to stop both servers."
echo ""

cd frontend
npm run dev
