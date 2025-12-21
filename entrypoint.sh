#!/bin/bash

# 1. Check if the 'ComfyUI-Manager' is missing in the mapped volume
if [ ! -d "/app/custom_nodes/ComfyUI-Manager" ]; then
    echo "⚠️  Local custom_nodes is empty or missing standard nodes. Copying pre-installed nodes..."
    
    # Copy from the temporary build location to the mounted volume
    cp -r /app/pre_installed_nodes/* /app/custom_nodes/
else
    echo "✅ Custom nodes found. Skipping copy."
fi

# 2. Run the Command passed to docker (start ComfyUI)
exec "$@"