#!/usr/bin/env python3
"""
validate_model.py - The Tier-1 Gatekeeper

This script validates a model folder before promotion to stable/.
It enforces the Metadata Contract and performs a Lightweight Smoke Test.

Usage:
    python scripts/validate_model.py <model_folder_path>

Exit Codes:
    0 - Validation passed
    1 - Tier-1 validation failed (blocking)
    2 - Model artifact corruption detected
"""

import sys
import os
import yaml
from pathlib import Path


# Tier-1 Required Fields (Blocking)
TIER_1_FIELDS = {
    "model_id": str,
    "git_hash": str,
    "framework": str,
    "min_app_version": str,
    "required_hardware": str,
}

VALID_FRAMEWORKS = ["pytorch", "tensorflow", "onnx"]
VALID_HARDWARE = ["mps", "cpu", "cuda"]


def load_metadata(model_path: Path) -> dict:
    """Load and parse metadata.yaml from the model folder."""
    metadata_file = model_path / "metadata.yaml"
    if not metadata_file.exists():
        print(f"❌ FATAL: metadata.yaml not found in {model_path}")
        sys.exit(1)
    
    with open(metadata_file, "r") as f:
        try:
            return yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"❌ FATAL: Invalid YAML in metadata.yaml: {e}")
            sys.exit(1)


def validate_tier_1(metadata: dict, model_folder_name: str) -> bool:
    """Validate Tier-1 (Blocking) fields."""
    print("🔍 Validating Tier-1 (Blocking) fields...")
    errors = []
    
    for field, expected_type in TIER_1_FIELDS.items():
        if field not in metadata:
            errors.append(f"  - Missing required field: '{field}'")
        elif not isinstance(metadata[field], expected_type):
            errors.append(f"  - Field '{field}' must be of type {expected_type.__name__}")
    
    # Validate model_id matches folder name
    if metadata.get("model_id") != model_folder_name:
        errors.append(f"  - 'model_id' ({metadata.get('model_id')}) must match folder name ({model_folder_name})")
    
    # Validate framework
    if metadata.get("framework") not in VALID_FRAMEWORKS:
        errors.append(f"  - 'framework' must be one of: {VALID_FRAMEWORKS}")
    
    # Validate hardware
    if metadata.get("required_hardware") not in VALID_HARDWARE:
        errors.append(f"  - 'required_hardware' must be one of: {VALID_HARDWARE}")
    
    if errors:
        print("❌ Tier-1 Validation FAILED:")
        for err in errors:
            print(err)
        return False
    
    print("✅ Tier-1 Validation PASSED")
    return True


def smoke_test_model(model_path: Path, framework: str) -> bool:
    """
    Lightweight Smoke Test: Attempt to load model weights.
    This ensures the artifact isn't corrupt.
    """
    print("🔥 Running Lightweight Smoke Test...")
    
    # Find model files based on framework
    if framework == "pytorch":
        model_files = list(model_path.glob("*.pt")) + list(model_path.glob("*.pth"))
        if not model_files:
            print("❌ No PyTorch model files (.pt/.pth) found")
            return False
        
        try:
            import torch
            for mf in model_files:
                print(f"  Loading {mf.name}...")
                # Just load to verify integrity, don't keep in memory
                torch.load(mf, map_location="cpu", weights_only=True)
            print("✅ Smoke Test PASSED (PyTorch)")
            return True
        except Exception as e:
            print(f"❌ Smoke Test FAILED: {e}")
            return False
    
    elif framework == "tensorflow":
        try:
            import tensorflow as tf
            saved_model_dir = model_path / "saved_model"
            if saved_model_dir.exists():
                tf.saved_model.load(str(saved_model_dir))
                print("✅ Smoke Test PASSED (TensorFlow)")
                return True
            else:
                print("❌ No saved_model directory found")
                return False
        except Exception as e:
            print(f"❌ Smoke Test FAILED: {e}")
            return False
    
    elif framework == "onnx":
        try:
            import onnx
            onnx_files = list(model_path.glob("*.onnx"))
            if not onnx_files:
                print("❌ No ONNX model files (.onnx) found")
                return False
            for mf in onnx_files:
                print(f"  Checking {mf.name}...")
                model = onnx.load(str(mf))
                onnx.checker.check_model(model)
            print("✅ Smoke Test PASSED (ONNX)")
            return True
        except Exception as e:
            print(f"❌ Smoke Test FAILED: {e}")
            return False
    
    print(f"⚠️  Smoke test not implemented for framework: {framework}")
    return True  # Allow pass for unknown frameworks with warning


def main():
    if len(sys.argv) != 2:
        print("Usage: python scripts/validate_model.py <model_folder_path>")
        sys.exit(1)
    
    model_path = Path(sys.argv[1]).resolve()
    
    if not model_path.exists():
        print(f"❌ FATAL: Model path does not exist: {model_path}")
        sys.exit(1)
    
    if not model_path.is_dir():
        print(f"❌ FATAL: Model path is not a directory: {model_path}")
        sys.exit(1)
    
    model_folder_name = model_path.name
    print(f"═══════════════════════════════════════════════════════════")
    print(f"  VALIDATING: {model_folder_name}")
    print(f"═══════════════════════════════════════════════════════════")
    
    # Load metadata
    metadata = load_metadata(model_path)
    
    # Tier-1 Validation (Blocking)
    if not validate_tier_1(metadata, model_folder_name):
        print("\n🚫 PROMOTION BLOCKED: Tier-1 validation failed.")
        sys.exit(1)
    
    # Smoke Test (Corruption Check)
    if not smoke_test_model(model_path, metadata.get("framework", "")):
        print("\n🚫 PROMOTION BLOCKED: Model artifact corruption detected.")
        sys.exit(2)
    
    print("\n✅ ALL VALIDATIONS PASSED. Model is eligible for promotion.")
    sys.exit(0)


if __name__ == "__main__":
    main()
