#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import yaml


APP_DIR = Path(__file__).resolve().parents[1]


def get_path(obj: dict[str, Any], dotted_path: str) -> Any:
    current: Any = obj
    for part in dotted_path.split("."):
        current = current[part]
    return current


def main() -> int:
    registry_path = APP_DIR / "workflow_registry.yaml"
    registry = yaml.safe_load(registry_path.read_text()) or {}
    workflows = registry.get("workflows") or {}
    errors: list[str] = []

    for workflow_id, config in workflows.items():
        workflow_path = APP_DIR / config["file"]
        if not workflow_path.exists():
            errors.append(f"{workflow_id}: missing workflow file {workflow_path}")
            continue

        workflow = json.loads(workflow_path.read_text())
        for label, dotted_path in (config.get("patch_points") or {}).items():
            try:
                get_path(workflow, dotted_path)
            except Exception as exc:
                errors.append(f"{workflow_id}: bad patch point {label}={dotted_path}: {exc}")

        for node_id in config.get("output_nodes") or []:
            if str(node_id) not in workflow:
                errors.append(f"{workflow_id}: missing output node {node_id}")

    if errors:
        print("Registry validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(f"OK: registry validates {len(workflows)} workflow(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
