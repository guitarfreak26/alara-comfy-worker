#!/usr/bin/env bash
set -euo pipefail

COMFY_DIR="${COMFY_DIR:-/opt/ComfyUI}"
MODEL_ROOT="${MODEL_ROOT:-/runpod-volume/comfy-models}"
COMFY_HOST="${COMFY_HOST:-127.0.0.1}"
COMFY_PORT="${COMFY_PORT:-8188}"

cd "${COMFY_DIR}"

echo "[start] model root: ${MODEL_ROOT}"
if [ ! -d "${MODEL_ROOT}" ]; then
  echo "[start] warning: model root does not exist: ${MODEL_ROOT}"
  echo "[start] /runpod-volume contents:"
  find /runpod-volume -maxdepth 3 -type d 2>/dev/null | sort | head -200 || true
fi
mkdir -p models input/luts output

link_model_dir() {
  local name="$1"
  local src="${MODEL_ROOT}/${name}"
  local dst="${COMFY_DIR}/models/${name}"

  if [ ! -e "${src}" ]; then
    echo "[start] warning: missing model dir ${src}"
    return 0
  fi

  rm -rf "${dst}"
  ln -s "${src}" "${dst}"
  echo "[start] linked models/${name} -> ${src}"
}

link_model_dir "checkpoints"
link_model_dir "diffusion_models"
link_model_dir "loras"
link_model_dir "text_encoders"
link_model_dir "upscale_models"
link_model_dir "ultralytics"
link_model_dir "vae"

if [ -f "${COMFY_DIR}/custom_nodes/ComfyUI-CameraForensicRealism/luts/AppleLog2_to_Rec709_33_Grid.cube" ]; then
  cp "${COMFY_DIR}/custom_nodes/ComfyUI-CameraForensicRealism/luts/AppleLog2_to_Rec709_33_Grid.cube" \
     "${COMFY_DIR}/input/luts/AppleLog2_to_Rec709_33_Grid.cube"
  echo "[start] copied Apple LUT into input/luts"
fi

exec python main.py \
  --listen "${COMFY_HOST}" \
  --port "${COMFY_PORT}" \
  --disable-auto-launch
