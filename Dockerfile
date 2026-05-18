FROM pytorch/pytorch:2.11.0-cuda12.8-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    COMFY_DIR=/opt/ComfyUI \
    MODEL_ROOT=/runpod-volume/comfy-models \
    COMFY_HOST=127.0.0.1 \
    COMFY_PORT=8188

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git ${COMFY_DIR}

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN python3 -m pip install --break-system-packages --no-cache-dir -r /app/requirements.txt

WORKDIR ${COMFY_DIR}
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY scripts/install_custom_nodes.sh /app/scripts/install_custom_nodes.sh
RUN chmod +x /app/scripts/install_custom_nodes.sh && /app/scripts/install_custom_nodes.sh

COPY . /app
RUN chmod +x /app/scripts/*.sh /app/scripts/*.py

WORKDIR /app
CMD ["python", "-u", "handler.py"]
