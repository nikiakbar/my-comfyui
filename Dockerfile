# FROM your base image
FROM comfyui-base:v1

ARG START_PORT=8188
ENV PORT=${START_PORT}

WORKDIR /app/pre_installed_nodes

COPY custom_nodes.txt /tmp/custom_nodes.txt

# 1. Parallel Clone (Fixed line endings)
RUN sed -i 's/\r$//' /tmp/custom_nodes.txt && \
    grep -v "^#" /tmp/custom_nodes.txt | grep -v "^$" | \
    awk '{print "https://github.com/" $1 ".git"}' | \
    xargs -n 1 -P 8 git clone

# 2. SAFETY NET: Explicitly install known problem packages
# We add 'torchlanc' here because WhiteRabbit needs it and sometimes misses it.
RUN uv pip install --system \
    opencv-python-headless \
    gguf \
    soundfile \
    piexif \
    torchlanc \
    imageio-ffmpeg \
    "huggingface_hub<0.25.0" \
    spandrel \
    sageattention \
    boto3

# 3. SEQUENTIAL INSTALL (The Fix)
# Instead of merging (which causes conflicts), we find each file and install it one by one.
# We add '|| true' so if ONE node has a broken requirement, it doesn't kill the whole build.
RUN find . -maxdepth 3 -name "requirements.txt" \
    -exec echo "Installing requirements for: {}" \; \
    -exec uv pip install --system --no-cache-dir -r {} \; \
    || true

# Reset Workdir
WORKDIR /app

# Setup Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create Directories
RUN mkdir -p models/checkpoints models/loras models/embeddings output input user custom_nodes

# Add Workflow
RUN mkdir -p /app/user/default/workflows
# COPY Detailer_V25.json /app/user/default/workflows/Detailer_V25.json

EXPOSE ${START_PORT}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sh", "-c", "python main.py --listen 0.0.0.0 --port ${PORT:-8188}"]