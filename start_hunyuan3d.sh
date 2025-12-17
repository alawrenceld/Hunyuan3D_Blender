#!/bin/bash
# Hunyuan3D Startup Script for Mac M4
# Starts both the Gradio Web UI and the API Server

cd ~/Hunyuan3D
source hy3d-venv/bin/activate
cd Hunyuan3D-2

echo "=========================================="
echo "  Hunyuan3D Local Server for Mac M4"
echo "=========================================="
echo ""
echo "Starting servers..."
echo ""

# Start API server in background on port 8081
echo "[1/2] Starting API Server on port 8081..."
python api_server.py --device mps --port 8081 &
API_PID=$!
echo "      API Server PID: $API_PID"

# Give API server a moment to start
sleep 2

# Start Gradio UI on port 7860
echo "[2/2] Starting Gradio Web UI on port 7860..."
python gradio_app.py --device mps --port 7860 &
GRADIO_PID=$!
echo "      Gradio UI PID: $GRADIO_PID"

echo ""
echo "=========================================="
echo "  Servers Starting..."
echo "=========================================="
echo ""
echo "  Web UI:  http://localhost:7860"
echo "  API:     http://localhost:8081"
echo ""
echo "  Note: Texture generation is disabled (requires CUDA)"
echo "        Shape generation works on MPS!"
echo ""
echo "  Press Ctrl+C to stop both servers"
echo "=========================================="
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down servers..."
    kill $API_PID 2>/dev/null
    kill $GRADIO_PID 2>/dev/null
    echo "Done."
    exit 0
}

# Trap Ctrl+C and call cleanup
trap cleanup SIGINT SIGTERM

# Wait for both processes
wait

