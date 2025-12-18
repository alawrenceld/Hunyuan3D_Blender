#!/bin/bash
# Hunyuan3D Update Script for Mac Apple Silicon
# Updates the Hunyuan3D-2 repository and dependencies

set -e  # Exit on error

echo "=========================================="
echo "  Hunyuan3D Updater for Mac M4"
echo "=========================================="
echo ""

cd ~/Hunyuan3D

# Check if servers are running and stop them
if pgrep -f "gradio_app.py" > /dev/null || pgrep -f "api_server.py" > /dev/null; then
    echo "⚠️  Stopping running Hunyuan3D servers..."
    pkill -f "gradio_app.py" 2>/dev/null || true
    pkill -f "api_server.py" 2>/dev/null || true
    sleep 2
    echo "   Servers stopped."
    echo ""
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source hy3d-venv/bin/activate
echo "   Python: $(python --version)"
echo ""

# Update the repository
echo "📥 Updating Hunyuan3D-2 repository..."
cd Hunyuan3D-2

# Stash any local changes
if [[ -n $(git status --porcelain) ]]; then
    echo "   Stashing local changes..."
    git stash
    STASHED=true
fi

# Pull latest changes
git fetch origin
CURRENT=$(git rev-parse HEAD)
git pull origin main

NEW=$(git rev-parse HEAD)
if [ "$CURRENT" = "$NEW" ]; then
    echo "   ✅ Already up to date!"
else
    echo "   ✅ Updated from ${CURRENT:0:7} to ${NEW:0:7}"
    
    # Show what changed
    echo ""
    echo "   Recent changes:"
    git log --oneline ${CURRENT}..${NEW} | head -10
fi

# Restore stashed changes if any
if [ "$STASHED" = true ]; then
    echo ""
    echo "   Restoring local changes..."
    git stash pop || echo "   ⚠️  Could not restore stashed changes automatically"
fi

echo ""

# Update Python dependencies
echo "📦 Updating Python dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --upgrade --quiet
echo "   ✅ Dependencies updated!"
echo ""

# Update PyTorch if needed
echo "🔥 Checking PyTorch..."
TORCH_VERSION=$(python -c "import torch; print(torch.__version__)")
MPS_AVAILABLE=$(python -c "import torch; print(torch.backends.mps.is_available())")
echo "   PyTorch version: $TORCH_VERSION"
echo "   MPS available: $MPS_AVAILABLE"
echo ""

# Clear old cache (optional, uncomment if needed)
# echo "🧹 Clearing old Gradio cache..."
# rm -rf ~/Hunyuan3D/Hunyuan3D-2/gradio_cache/*
# echo "   Cache cleared!"
# echo ""

# Summary
echo "=========================================="
echo "  ✅ Update Complete!"
echo "=========================================="
echo ""
echo "  To start Hunyuan3D, run:"
echo "    ~/Hunyuan3D/start_hunyuan3d.sh"
echo ""
echo "  Or if you have the alias:"
echo "    hunyuan3d"
echo ""
echo "=========================================="

