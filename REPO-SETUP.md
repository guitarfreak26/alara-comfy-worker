# GitHub Build Setup

This worker should be pushed as a small standalone private repo, not as part of the main Fanvue workspace.

Recommended repo:

```text
alara-comfy-worker
```

Create and push:

```bash
cd /Users/alannewton/clawd/fanvue-automation/runpod-comfy-worker
git init
git add .
git commit -m "Initial ALARA ComfyUI RunPod worker"
gh repo create alara-comfy-worker --private --source=. --remote=origin --push
```

Then run:

```bash
gh workflow run build-ghcr.yml
gh run watch
```

Expected image:

```text
ghcr.io/guitarfreak26/alara-comfy-worker:seoyeon-zimage-v1
```

Use that image in RunPod Serverless.
