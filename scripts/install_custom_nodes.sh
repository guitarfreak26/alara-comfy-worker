#!/usr/bin/env bash
set -euo pipefail

COMFY_DIR="${COMFY_DIR:-/opt/ComfyUI}"
CUSTOM_NODES_DIR="${COMFY_DIR}/custom_nodes"

mkdir -p "${CUSTOM_NODES_DIR}"
cd "${CUSTOM_NODES_DIR}"

clone_or_update() {
  local name="$1"
  local repo="$2"
  local ref="${3:-}"

  if [ -d "${name}/.git" ]; then
    echo "[custom-nodes] ${name} already exists"
    return 0
  fi

  echo "[custom-nodes] cloning ${name} from ${repo}"
  git clone --depth 1 "${repo}" "${name}"

  if [ -n "${ref}" ]; then
    (cd "${name}" && git fetch --depth 1 origin "${ref}" && git checkout "${ref}")
  fi
}

clone_or_update "HydroSharksampler" "https://github.com/MONKEYFOREVER2/HydroSharksampler.git"
clone_or_update "comfyui-quantum-spectral-nodes" "https://github.com/MONKEYFOREVER2/comfyui-quantum-spectral-nodes.git"
clone_or_update "advanced-denoiser" "https://github.com/MONKEYFOREVER2/comfyui-advanced-denoiser.git"
clone_or_update "ComfyUI-CameraForensicRealism" "https://github.com/MONKEYFOREVER2/ComfyUI-CameraForensicRealism.git"
clone_or_update "ComfyUI-ZenFaceDetailer" "https://github.com/MONKEYFOREVER2/ComfyUI-ZenFaceDetailer.git"
clone_or_update "ComfyUI-ZImage-LoRA-Merger" "https://github.com/DanrisiUA/ComfyUI-ZImage-LoRA-Merger.git"
clone_or_update "ComfyUI-KJNodes" "https://github.com/kijai/ComfyUI-KJNodes.git"
clone_or_update "comfyui-impact-pack" "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
clone_or_update "comfyui-impact-subpack" "https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git"
clone_or_update "rgthree-comfy" "https://github.com/rgthree/rgthree-comfy.git"
clone_or_update "comfyui-machinepainting-nodes" "https://github.com/machinepainting/ComfyUI-MachinePaintingNodes.git"
clone_or_update "crt-nodes" "https://github.com/PGCRT/CRT-Nodes.git"

for req in "${CUSTOM_NODES_DIR}"/*/requirements.txt; do
  [ -f "${req}" ] || continue
  echo "[custom-nodes] installing requirements from ${req}"
  python -m pip install --no-cache-dir -r "${req}"
done

echo "[custom-nodes] complete"
