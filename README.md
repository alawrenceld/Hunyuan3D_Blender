# Hunyuan3D Local Setup Guide for Mac (Apple Silicon)

This guide walks you through setting up Tencent's Hunyuan3D-2 locally on a Mac with Apple Silicon (M1/M2/M3/M4). This enables free, local 3D model generation from images without relying on cloud APIs.

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Running Hunyuan3D](#running-hunyuan3d)
- [Usage](#usage)
- [Integration with Blender MCP](#integration-with-blender-mcp)
- [Limitations](#limitations)
- [Troubleshooting](#troubleshooting)

---

## Requirements

### Hardware
- **Mac with Apple Silicon** (M1, M2, M3, or M4)
- **16GB RAM minimum** (32GB+ recommended for better performance)
- **50GB+ free disk space** (for models and cache)

### Software
- **macOS 12.0+** (Monterey or later, Sonoma recommended)
- **Homebrew** (package manager)
- **Python 3.10** (installed via Homebrew)

---

## Installation

### Step 1: Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install Python 3.10

```bash
brew install python@3.10
```

### Step 3: Install Rust (required for some dependencies)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
```

### Step 4: Create Project Directory and Virtual Environment

```bash
# Create directory
mkdir -p ~/Hunyuan3D
cd ~/Hunyuan3D

# Create virtual environment with Python 3.10
/opt/homebrew/bin/python3.10 -m venv hy3d-venv

# Activate virtual environment
source hy3d-venv/bin/activate
```

### Step 5: Clone Hunyuan3D-2 Repository

```bash
git clone https://github.com/Tencent/Hunyuan3D-2.git
cd Hunyuan3D-2
```

### Step 6: Install PyTorch with MPS Support

```bash
pip install --upgrade pip
pip install torch torchvision torchaudio
```

### Step 7: Install Dependencies

```bash
pip install -r requirements.txt
```

### Step 8: Verify MPS (Metal Performance Shaders) is Available

```bash
python -c "import torch; print(f'MPS available: {torch.backends.mps.is_available()}')"
```

You should see: `MPS available: True`

### Step 9: Download Pre-trained Models

The models will download automatically on first use, but you can pre-download them:

```bash
python -c "
from huggingface_hub import snapshot_download
snapshot_download(repo_id='tencent/Hunyuan3D-2', local_dir='./weights/Hunyuan3D-2')
"
```

> **Note:** This downloads approximately 20-30GB of model weights.

---

## Running Hunyuan3D

### Option 1: Use the Startup Script (Recommended)

Create the startup script at `~/Hunyuan3D/start_hunyuan3d.sh`:

```bash
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
```

Make it executable and run:

```bash
chmod +x ~/Hunyuan3D/start_hunyuan3d.sh
~/Hunyuan3D/start_hunyuan3d.sh
```

### Option 2: Run Servers Individually

**Gradio Web UI only:**
```bash
cd ~/Hunyuan3D
source hy3d-venv/bin/activate
cd Hunyuan3D-2
python gradio_app.py --device mps --port 7860
```

**API Server only:**
```bash
cd ~/Hunyuan3D
source hy3d-venv/bin/activate
cd Hunyuan3D-2
python api_server.py --device mps --port 8081
```

### Option 3: Add Shell Alias (Convenience)

Add to your `~/.zshrc`:

```bash
echo 'alias hunyuan3d="~/Hunyuan3D/start_hunyuan3d.sh"' >> ~/.zshrc
source ~/.zshrc
```

Now you can start everything by typing: `hunyuan3d`

---

## Usage

### Web UI (Gradio)

1. Open your browser to **http://localhost:7860**
2. Upload an image (PNG with transparent background works best)
3. Adjust settings if needed:
   - **Octree Resolution:** Higher = more detail (default: 256)
   - **Inference Steps:** More steps = better quality (default: 20)
   - **Guidance Scale:** Controls adherence to input (default: 5.5)
4. Click **Generate**
5. Download the resulting `.glb` file

### API Server

The API server runs on **http://localhost:8081** and accepts POST requests.

**Endpoints:**
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/generate` | POST | Generate 3D model from image |
| `/status/{uid}` | GET | Check generation status |

**Example API Call (Python):**
```python
import requests
import base64

# Load and encode image
with open("my_image.png", "rb") as f:
    image_b64 = base64.b64encode(f.read()).decode()

# Send request
response = requests.post(
    "http://localhost:8081/generate",
    json={
        "image": image_b64,
        "num_inference_steps": 20,
        "octree_resolution": 256,
        "guidance_scale": 5.5
    }
)

# Save result
with open("output.glb", "wb") as f:
    f.write(response.content)
```

### Python Script (Direct Usage)

```python
from PIL import Image
from hy3dgen.rembg import BackgroundRemover
from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline

# Load pipeline
pipeline = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(
    'tencent/Hunyuan3D-2', 
    device='mps'
)

# Load and preprocess image
image = Image.open('my_image.png').convert('RGBA')
rembg = BackgroundRemover()
image = rembg(image)

# Generate 3D mesh
mesh = pipeline(image=image, num_inference_steps=30)[0]

# Export
mesh.export('output.glb')
```

---

## Integration with Blender MCP

If you're using the [Blender MCP](https://github.com/ahujasid/blender-mcp) addon:

1. In Blender, press **N** to open the sidebar
2. Find the **BlenderMCP** panel
3. Check **"Use Tencent Hunyuan 3D model generation"**
4. Set the API URL to: `http://localhost:8081`
5. Configure settings:
   - Octree Resolution: 256
   - Number of Inference Steps: 20
   - Guidance Scale: 5.5

Now you can generate 3D models directly from within Blender using your local Hunyuan3D instance!

---

## Limitations

### What Works on Mac (MPS)
- ✅ **Shape generation** - Full 3D mesh generation from images
- ✅ **Background removal** - Automatic via rembg
- ✅ **Multiple model variants** - Full, mini, and turbo models

### What Doesn't Work on Mac
- ❌ **Texture generation** - Requires CUDA (NVIDIA GPU only)
  - The custom rasterizer needs CUDA to compile
  - Generated meshes will be untextured (white/gray)
- ⚠️ **Performance** - Slower than NVIDIA GPUs (expect 3-5 minutes per generation)

### Workaround for Textures
You can add materials manually in Blender or use other texturing tools after generation.

---

## Troubleshooting

### "MPS available: False"
- Ensure you're using Python from Homebrew, not the system Python
- Reinstall PyTorch: `pip install --force-reinstall torch torchvision torchaudio`

### "No module named 'custom_rasterizer'"
- This is expected on Mac - it's only needed for texture generation
- Shape generation will still work

### Generation produces empty/cube mesh
- Ensure your input image has a **transparent or solid background**
- Use the background remover: images with complex backgrounds may fail
- Try increasing `num_inference_steps` to 30

### Out of memory errors
- Close other applications to free RAM
- Try the mini model: use `tencent/Hunyuan3D-2mini` instead
- Reduce `octree_resolution` to 128

### Port already in use
- Check for existing processes: `lsof -i :7860` or `lsof -i :8081`
- Kill them: `pkill -f gradio_app` or `pkill -f api_server`

### Slow generation
- First run downloads models (~20GB) - subsequent runs are faster
- MPS is slower than CUDA - expect 3-5 minutes per generation
- The mini-turbo model is faster but lower quality

---

## File Locations

| Item | Location |
|------|----------|
| Virtual Environment | `~/Hunyuan3D/hy3d-venv/` |
| Source Code | `~/Hunyuan3D/Hunyuan3D-2/` |
| Startup Script | `~/Hunyuan3D/start_hunyuan3d.sh` |
| Model Cache | `~/.cache/huggingface/hub/` |
| Gradio Cache | `~/Hunyuan3D/Hunyuan3D-2/gradio_cache/` |

---

## Stopping the Servers

If using the startup script, press **Ctrl+C** to stop both servers.

To manually stop:
```bash
pkill -f gradio_app.py
pkill -f api_server.py
```

---

## Credits

- [Hunyuan3D-2](https://github.com/Tencent/Hunyuan3D-2) by Tencent
- [Blender MCP](https://github.com/ahujasid/blender-mcp) for Blender integration

---

*Last updated: December 2024*

