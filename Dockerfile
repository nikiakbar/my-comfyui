# Use NVIDIA base for guaranteed driver compatibility
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Set shell to bash
SHELL ["/bin/bash", "-c"]

WORKDIR /app

# 1. Install System Deps
# ffmpeg: for video nodes
# git/wget: for downloading nodes/models
# libgl1/libglib2.0: for OpenCV
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    git \
    wget \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 2. Set Python 3.11 as default
# This ensures 'python' command calls python3.11
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# 3. Upgrade pip
RUN python -m pip install --upgrade pip

# 4. Clone ComfyUI
# We clone into /app/ComfyUI to keep things organized
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# 5. Install PyTorch & Dependencies
# We install Torch specifically for CUDA 12.1 to match the base image
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# 6. Install ComfyUI requirements
RUN pip install -r requirements.txt

# 7. Create directory structure for mapping
# This ensures permissions exist before mounting
RUN mkdir -p models/checkpoints models/loras models/embeddings output input custom_nodes

# 8. Expose Port
EXPOSE 8188

# 9. Startup Command
# --listen is required for Docker
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]