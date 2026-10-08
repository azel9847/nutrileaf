"""HHC-VNDC hierarchical inference pipeline.

Architecture
------------
Stage 1  — MobileNetV4-Conv-Small (timm: mobilenetv4_conv_small.e2400_r224_in1k)
           Classifies leaf images into one of 5 vegetables:
           ampalaya, kalabasa, okra, sitaw, talong.

Stage 2  — MobileViT-S (timm: mobilevit_s.cvnets_in1k)
           Classifies deficiency from the same preprocessed image into:
           healthy, nitrogen, phosphorus, potassium.

Both models receive the same 224×224 ImageNet-normalised tensor.
Stage 2 is run unconditionally (not per-vegetable expert) on the full
4-class deficiency head; the Stage 1 crop label is reported alongside.

Checkpoint configuration (via environment variables)
----------------------------------------------------
HHC_STAGE1_CHECKPOINT   — path to MobileNetV4 Stage-1 .pth file
                          (default: models/mobilenetv4_stage1.pth)
HHC_STAGE2_CHECKPOINT   — path to MobileViT-S Stage-2 .pth file
                          (default: models/mobilevit_stage2.pth)
HHC_DEVICE              — "cpu" (default) or "cuda"
"""
from __future__ import annotations

import io
import logging
import os
from pathlib import Path
from typing import Any

import timm
import torch
import torch.nn as nn
from PIL import Image, ImageOps
from torchvision import transforms

logger = logging.getLogger("nutrileaf.hhc")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

VEGETABLES: tuple[str, ...] = ("ampalaya", "kalabasa", "okra", "sitaw", "talong")
DEFICIENCIES: tuple[str, ...] = ("healthy", "nitrogen", "phosphorus", "potassium")

# Default relative checkpoint paths (resolved from the backend working directory)
_DEFAULT_STAGE1_PATH = Path("models/mobilenetv4_stage1.pth")
_DEFAULT_STAGE2_PATH = Path("models/mobilevit_stage2.pth")


# ---------------------------------------------------------------------------
# Preprocessing — unified for both stages
# ---------------------------------------------------------------------------

# Resize to 224×224, convert to float tensor in [0, 1], then ImageNet-normalise.
# Both MobileNetV4 and MobileViT-S were fine-tuned on 224×224 inputs with
# these exact mean/std values; no crop step is needed when the Flutter
# frontend already sends a 1:1 square image.
_TRANSFORM = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225],
    ),
])


# ---------------------------------------------------------------------------
# Checkpoint loading helper
# ---------------------------------------------------------------------------

def _load_state_dict(model: nn.Module, path: Path) -> nn.Module:
    """Load a .pth checkpoint into *model* in-place and return it.

    Handles three common checkpoint formats:
    1. Serialised nn.Module      — returned as-is.
    2. Raw state_dict            — loaded directly.
    3. Training wrapper dict     — state_dict extracted from the
                                   ``"state_dict"`` or ``"model_state_dict"``
                                   key (e.g. Lightning / custom trainers).

    A ``"module."`` prefix (added by DataParallel / DDP) is stripped
    automatically before loading.
    """
    payload: Any = torch.load(path, map_location="cpu", weights_only=False)

    if isinstance(payload, nn.Module):
        logger.info("Checkpoint '%s' is a serialised nn.Module — using directly.", path.name)
        return payload

    if isinstance(payload, dict):
        state_dict = payload.get(
            "state_dict", payload.get("model_state_dict", payload)
        )
    else:
        raise ValueError(
            f"Unsupported checkpoint format at '{path}'. "
            "Expected nn.Module, state_dict dict, or training wrapper dict."
        )

    # Strip DataParallel / DDP prefix
    cleaned = {str(k).removeprefix("module."): v for k, v in state_dict.items()}

    missing, unexpected = model.load_state_dict(cleaned, strict=False)
    if missing:
        logger.warning("Checkpoint '%s': %d missing key(s).", path.name, len(missing))
        logger.debug("Missing keys: %s", missing)
    if unexpected:
        logger.warning("Checkpoint '%s': %d unexpected key(s).", path.name, len(unexpected))
        logger.debug("Unexpected keys: %s", unexpected)

    return model


# Legacy key fragments from old fusion checkpoints that must be purged before
# loading into a pure MobileNetV4 model.  Any state_dict key whose name
# contains one of these substrings belongs to a removed sub-network and would
# cause load_state_dict to raise unexpected-key warnings or silently corrupt
# the model if loaded via strict=False without filtering.
_LEGACY_KEY_FRAGMENTS: tuple[str, ...] = ("swin", "cbam", "efficient")


def _load_stage1_state_dict(model: nn.Module, path: Path) -> nn.Module:
    """Load a MobileNetV4 Stage-1 checkpoint with dynamic weight cleaning.

    This function is needed because Stage-1 .pth files may have been saved
    from an older fusion architecture (EfficientNetV2-S + Swin-T + CBAM).
    The cleaning steps below make loading safe and deterministic:

    1. Unwrap training-wrapper dicts (``state_dict`` / ``model_state_dict`` key).
    2. Strip the ``"module."`` DDP/DataParallel prefix from all keys.
    3. **Filter** — remove any key containing ``'swin'``, ``'cbam'``, or
       ``'efficient'``.  These belong to removed sub-networks and must not
       be injected into a pure MobileNetV4 model.
    4. **Classifier shape guard** — if the checkpoint's ``classifier.weight``
       shape does not match the model's expected shape, drop both
       ``classifier.weight`` and ``classifier.bias`` so the randomly
       initialised head is used instead of a mismatched one.
    5. Load the cleaned dict with ``strict=False`` and log key statistics.
    """
    payload: Any = torch.load(path, map_location="cpu", weights_only=False)

    # Unwrap serialised nn.Module checkpoints
    if isinstance(payload, nn.Module):
        logger.info("Stage-1 checkpoint '%s' is a serialised nn.Module — using directly.", path.name)
        return payload

    if isinstance(payload, dict):
        raw_sd = payload.get("state_dict", payload.get("model_state_dict", payload))
    else:
        raise ValueError(
            f"Unsupported checkpoint format at '{path}'. "
            "Expected nn.Module, state_dict dict, or training wrapper dict."
        )

    # Step 1 — strip DDP / DataParallel prefix
    stripped: dict[str, Any] = {
        str(k).removeprefix("module."): v for k, v in raw_sd.items()
    }

    # Step 2 — purge legacy sub-network keys (Swin, CBAM, EfficientNet)
    cleaned_dict: dict[str, Any] = {
        k: v for k, v in stripped.items()
        if not any(frag in k.lower() for frag in _LEGACY_KEY_FRAGMENTS)
    }
    purged = len(stripped) - len(cleaned_dict)
    if purged:
        logger.info(
            "Stage-1: purged %d legacy key(s) containing %s from checkpoint.",
            purged, _LEGACY_KEY_FRAGMENTS,
        )

    # Step 3 — classifier shape guard
    expected_shape = model.classifier.weight.shape  # type: ignore[union-attr]
    if "classifier.weight" in cleaned_dict:
        ckpt_shape = cleaned_dict["classifier.weight"].shape
        if ckpt_shape != expected_shape:
            logger.warning(
                "Stage-1: classifier.weight shape mismatch — "
                "checkpoint has %s, model expects %s. "
                "Dropping classifier weights; head will use random init.",
                ckpt_shape, expected_shape,
            )
            cleaned_dict.pop("classifier.weight", None)
            cleaned_dict.pop("classifier.bias", None)

    # Step 4 — load with strict=False and report
    missing, unexpected = model.load_state_dict(cleaned_dict, strict=False)
    if missing:
        logger.warning("Stage-1: %d missing key(s) after cleaning.", len(missing))
        logger.debug("Missing: %s", missing)
    if unexpected:
        logger.warning("Stage-1: %d unexpected key(s) after cleaning.", len(unexpected))
        logger.debug("Unexpected: %s", unexpected)

    logger.info(
        "Stage-1: loaded %d/%d keys from '%s'.",
        len(cleaned_dict) - len(unexpected),
        len(cleaned_dict),
        path.name,
    )
    return model


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

class HHCInferencePipeline:
    """Two-stage HHC-VNDC inference pipeline.

    Stage 1 — MobileNetV4-Conv-Small: identifies the vegetable crop.
    Stage 2 — MobileViT-S: diagnoses the nutrient deficiency.

    Both stages consume the *same* preprocessed 224×224 tensor so the
    preprocessing cost is paid only once per request.

    Usage::

        pipeline = HHCInferencePipeline()
        if pipeline.ready:
            result = pipeline.predict(image_bytes)

    ``predict`` returns a dict with the following keys::

        crop                     — predicted vegetable (str)
        deficiency               — predicted deficiency label (str)
        confidence_stage1        — Stage-1 top-class softmax probability (float)
        confidence_stage2        — Stage-2 top-class softmax probability (float)
        vegetable_probabilities  — {vegetable: prob} for all 5 Stage-1 classes
        deficiency_probabilities — {deficiency: prob} for all 4 Stage-2 classes
    """

    def __init__(self) -> None:
        self.device = torch.device(
            os.getenv("HHC_DEVICE", "cuda" if torch.cuda.is_available() else "cpu")
        )
        self.stage1: nn.Module | None = None
        self.stage2: nn.Module | None = None
        self._load_error: str | None = None
        self._load_models()

    # ------------------------------------------------------------------
    # Public properties
    # ------------------------------------------------------------------

    @property
    def ready(self) -> bool:
        """True when both models loaded without error."""
        return (
            self._load_error is None
            and self.stage1 is not None
            and self.stage2 is not None
        )

    @property
    def load_error(self) -> str | None:
        """Human-readable error string, or None if models loaded cleanly."""
        return self._load_error

    # ------------------------------------------------------------------
    # Model loading
    # ------------------------------------------------------------------

    def _resolve_checkpoint(self, env_var: str, default: Path) -> Path:
        """Return the checkpoint path from an env var, falling back to *default*."""
        raw = os.getenv(env_var, "").strip()
        return Path(raw) if raw else default

    def _load_models(self) -> None:
        """Instantiate and load both stage models.

        Sets ``self._load_error`` on any failure so the server can surface a
        descriptive message without crashing at import time.
        """
        stage1_path = self._resolve_checkpoint("HHC_STAGE1_CHECKPOINT", _DEFAULT_STAGE1_PATH)
        stage2_path = self._resolve_checkpoint("HHC_STAGE2_CHECKPOINT", _DEFAULT_STAGE2_PATH)

        missing: list[str] = []
        if not stage1_path.exists():
            missing.append(f"Stage-1 (MobileNetV4) checkpoint not found: '{stage1_path}'")
        if not stage2_path.exists():
            missing.append(f"Stage-2 (MobileViT-S)  checkpoint not found: '{stage2_path}'")

        if missing:
            self._load_error = (
                "HHC checkpoints missing — set HHC_STAGE1_CHECKPOINT / "
                "HHC_STAGE2_CHECKPOINT or place files at the default paths:\n  "
                + "\n  ".join(missing)
            )
            logger.warning(self._load_error)
            return

        try:
            # ── Stage 1: MobileNetV4-Conv-Small ──────────────────────────────
            # Uses a dedicated loader that strips legacy Swin/CBAM/EfficientNet
            # keys that may still be present in the .pth file, and guards
            # against classifier head shape mismatches.
            logger.info("Loading Stage-1 (MobileNetV4) from '%s' ...", stage1_path)
            s1 = timm.create_model(
                "mobilenetv4_conv_small.e2400_r224_in1k",
                pretrained=False,
                num_classes=len(VEGETABLES),
            )
            self.stage1 = (
                _load_stage1_state_dict(s1, stage1_path)
                .to(self.device)
                .eval()
            )
            logger.info(
                "Stage-1 ready — %d classes: %s", len(VEGETABLES), VEGETABLES
            )

            # ── Stage 2: MobileViT-S ─────────────────────────────────────────
            logger.info("Loading Stage-2 (MobileViT-S) from '%s' ...", stage2_path)
            s2 = timm.create_model(
                "mobilevit_s.cvnets_in1k",
                pretrained=False,
                num_classes=len(DEFICIENCIES),
            )
            self.stage2 = (
                _load_state_dict(s2, stage2_path)
                .to(self.device)
                .eval()
            )
            logger.info(
                "Stage-2 ready — %d classes: %s", len(DEFICIENCIES), DEFICIENCIES
            )

            logger.info(
                "HHC-VNDC pipeline fully loaded on device '%s'.", self.device
            )

        except Exception as exc:
            self._load_error = f"HHC model loading failed: {exc}"
            logger.exception(self._load_error)

    # ------------------------------------------------------------------
    # Inference
    # ------------------------------------------------------------------

    @torch.inference_mode()
    def predict(self, image_bytes: bytes) -> dict[str, Any]:
        """Run the two-stage HHC-VNDC pipeline on raw image bytes.

        Parameters
        ----------
        image_bytes:
            Raw bytes of a JPEG / PNG / WebP image.
            The Flutter frontend sends a 1:1 square, so no crop step is needed.

        Returns
        -------
        dict
            crop                     — predicted vegetable name (str)
            deficiency               — predicted deficiency label (str)
            confidence_stage1        — Stage-1 top-class softmax probability (float)
            confidence_stage2        — Stage-2 top-class softmax probability (float)
            vegetable_probabilities  — {vegetable: prob} for all 5 classes
            deficiency_probabilities — {deficiency: prob} for all 4 classes
        """
        if not self.ready:
            raise RuntimeError(self.load_error or "HHC pipeline is unavailable.")

        # ── Preprocessing (shared by both stages) ─────────────────────────────
        # PIL load forces RGB — avoids BGR channel-order issues from other decoders.
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        # Honour EXIF orientation tags so smartphone images always arrive upright.
        image = ImageOps.exif_transpose(image)
        tensor = _TRANSFORM(image).unsqueeze(0).to(self.device)  # [1, 3, 224, 224]

        logger.debug("Input image size: %s  |  tensor shape: %s", image.size, tensor.shape)

        # ── Stage 1: crop identification ──────────────────────────────────────
        veg_logits = self.stage1(tensor)                          # type: ignore[misc]
        veg_probs = torch.softmax(veg_logits, dim=1)[0]
        veg_idx = int(veg_probs.argmax())
        crop = VEGETABLES[veg_idx]
        confidence_stage1 = round(float(veg_probs[veg_idx]), 6)

        logger.info("Stage-1 → %s (%.1f%%)", crop, confidence_stage1 * 100)

        # ── Stage 2: deficiency diagnosis (same tensor, independent pass) ─────
        def_logits = self.stage2(tensor)                          # type: ignore[misc]
        def_probs = torch.softmax(def_logits, dim=1)[0]
        def_idx = int(def_probs.argmax())
        deficiency = DEFICIENCIES[def_idx]
        confidence_stage2 = round(float(def_probs[def_idx]), 6)

        logger.info("Stage-2 → %s (%.1f%%)", deficiency, confidence_stage2 * 100)

        return {
            "crop": crop,
            "deficiency": deficiency,
            "confidence_stage1": confidence_stage1,
            "confidence_stage2": confidence_stage2,
            "vegetable_probabilities": {
                label: round(float(prob), 6)
                for label, prob in zip(VEGETABLES, veg_probs)
            },
            "deficiency_probabilities": {
                label: round(float(prob), 6)
                for label, prob in zip(DEFICIENCIES, def_probs)
            },
        }
