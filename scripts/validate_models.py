#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate model files required by workflow registry.")
    parser.add_argument("--registry", default="workflow_registry.yaml")
    parser.add_argument("--model-root", default="/runpod-volume/comfy-models")
    parser.add_argument("--workflow-id", default="")
    args = parser.parse_args()

    registry_path = Path(args.registry)
    model_root = Path(args.model_root)
    registry = yaml.safe_load(registry_path.read_text()) or {}
    workflows = registry.get("workflows", {})
    selected = {args.workflow_id: workflows[args.workflow_id]} if args.workflow_id else workflows

    missing: list[str] = []
    for workflow_id, workflow in selected.items():
        for folder, filenames in (workflow.get("models") or {}).items():
            for filename in filenames or []:
                candidate = model_root / folder / filename
                if not candidate.exists():
                    missing.append(f"{workflow_id}: {candidate}")

    if missing:
        print("Missing required model files:", file=sys.stderr)
        for item in missing:
            print(f"  - {item}", file=sys.stderr)
        return 1

    print(f"OK: model manifest satisfied for {len(selected)} workflow(s) under {model_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
