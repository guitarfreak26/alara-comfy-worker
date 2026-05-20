# ALARA RunPod ComfyUI Worker

Minimal RunPod Serverless worker for ALARA ComfyUI workflows.

First registered workflow:

```text
seoyeon-zimage-full-quality-v1
seoyeon-zimage-clean-base-v1
seoyeon-zimage-good-selfie-v1
```

This is the canonical full-quality Seoyeon Z-Image workflow Alan tested on a normal RunPod ComfyUI pod. It includes the full detailer/upscale/camera path. The final LUT node is kept in the graph but defaults to intensity `0` for serverless, because the full Apple LUT produced a blue colour cast in the first Hermes run.

`seoyeon-zimage-clean-base-v1` is a diagnostic/clean lane that saves directly after the base Z-Image VAE decode. It bypasses the SDXL adult detailers, face detailer, denoiser, camera forensic node, LUT, and final upscalers so we can separate LoRA/prompt quality from postprocess overcooking.

`seoyeon-zimage-good-selfie-v1` is Alan's NEWTEST export after fixing the gritty selfie issue on the pod. It keeps the detailer path but uses the smoother LoRA/denoiser settings from that known-good lane.

## Layout

```text
Dockerfile
handler.py
workflow_registry.yaml
workflows/
scripts/
```

The handler is generic enough for multiple workflows, but the first milestone intentionally registers only one.

## Model Volume

The container expects RunPod Network Volume models at:

```text
/runpod-volume/comfy-models
```

Required structure:

```text
/runpod-volume/comfy-models/diffusion_models/zImageTurbo_turbo.safetensors
/runpod-volume/comfy-models/text_encoders/qwen_3_4b.safetensors
/runpod-volume/comfy-models/vae/zimagevae.safetensors
/runpod-volume/comfy-models/loras/SeoZ2500.safetensors
/runpod-volume/comfy-models/loras/RealLORA.safetensors
/runpod-volume/comfy-models/loras/Mystic-XXX-ZIT-V7.safetensors
/runpod-volume/comfy-models/checkpoints/lustifySDXLNSFW_apexV8.safetensors
/runpod-volume/comfy-models/ultralytics/bbox/female-breast-v4.7.pt
/runpod-volume/comfy-models/ultralytics/bbox/vagina-v4.2.pt
/runpod-volume/comfy-models/ultralytics/bbox/face_yolov9c.pt
/runpod-volume/comfy-models/upscale_models/2x_PureVision.pth
/runpod-volume/comfy-models/upscale_models/1x-ITF-SkinDiffDetail-Lite-v1.pth
```

The startup script symlinks these folders into `ComfyUI/models/`.

The Apple LUT is copied from `ComfyUI-CameraForensicRealism` into:

```text
ComfyUI/input/luts/AppleLog2_to_Rec709_33_Grid.cube
```

before ComfyUI starts.

## Local Validation

From this directory:

```bash
python3 scripts/validate_registry.py
```

If you have the model volume mounted locally:

```bash
python3 scripts/validate_models.py \
  --registry workflow_registry.yaml \
  --model-root /runpod-volume/comfy-models \
  --workflow-id seoyeon-zimage-full-quality-v1
```

## Build Image

Use your Docker registry name:

```bash
docker build -t YOUR_DOCKER_USER/alara-comfy-worker:seoyeon-zimage-v1 .
docker push YOUR_DOCKER_USER/alara-comfy-worker:seoyeon-zimage-v1
```

For GHCR:

```bash
docker build -t ghcr.io/YOUR_GITHUB_USER/alara-comfy-worker:seoyeon-zimage-v1 .
docker push ghcr.io/YOUR_GITHUB_USER/alara-comfy-worker:seoyeon-zimage-v1
```

## RunPod Serverless

Built test image:

```text
ghcr.io/guitarfreak26/alara-comfy-worker:seoyeon-zimage-v1
sha256:321a16fa40c98affdb0b446b8e71a7354e1839b79528549cc417be8175fe364f
```

The GitHub repo/package is private by default. RunPod needs GHCR credentials with
`read:packages`, or the container package must be made public before the endpoint
can pull this image anonymously.

Create a Serverless endpoint:

- Docker image: the pushed image
- GPU: start with RTX 4090/5090 or RTX 6000 class
- Attach the Network Volume containing `/comfy-models`
- Min workers: `0`
- Max workers: `1` for first debug run
- Timeout: start high, e.g. `900` seconds

Environment variables are optional unless paths differ:

```text
MODEL_ROOT=/runpod-volume/comfy-models
COMFY_DIR=/opt/ComfyUI
COMFY_PORT=8188
MAX_COUNT=4
```

## Test Request

```json
{
  "input": {
    "workflow_id": "seoyeon-zimage-full-quality-v1",
    "prompt": "seoyeonzimage, raw phone selfie, grey wall, soft indoor light, natural skin texture",
    "negative_prompt": "",
    "seed": -1,
    "aspect_ratio": "portrait",
    "count": 1,
    "return_base64": true
  }
}
```

Response shape:

```json
{
  "status": "success",
  "workflow_id": "seoyeon-zimage-full-quality-v1",
  "prompt_id": "...",
  "seed": 123,
  "outputs": [
    {
      "type": "image",
      "node_id": "37",
      "filename": "...png",
      "subfolder": "ALARA/...",
      "path_type": "output",
      "path": "/opt/ComfyUI/output/...",
      "base64": "..."
    }
  ]
}
```

Set `return_base64` to `false` once output upload to R2/S3/etc. exists.

## Add Another Workflow

1. Export API-format JSON from ComfyUI.
2. Copy it into `workflows/`.
3. Add an entry to `workflow_registry.yaml`.
4. Add missing model files to the Network Volume.
5. Add any missing custom node repos to `scripts/install_custom_nodes.sh`.
6. Run:

```bash
python3 scripts/validate_registry.py
```

The handler should not need internal edits for normal prompt/seed/size/count workflows.

## Known First-Run Risks

- Custom nodes are currently installed from live GitHub default branches. For production, pin each repo to the exact commit tested on Alan's pod.
- The workflow depends on the original LUT widget state from the tested ComfyUI export. Make sure the Apple LUT is available before ComfyUI starts.
- First cold start may be slow because ComfyUI and custom nodes load inside the worker.
- The first endpoint should be treated as experimental until one successful RunPod Serverless generation is verified.
