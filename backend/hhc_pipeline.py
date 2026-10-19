"""HHC-VNDC hierarchical inference pipeline.

Architecture
------------
Stage 1  — ConvNeXt-Tiny (timm: convnext_tiny)
           Classifies leaf images into one of 5 vegetables:
           ampalaya, kalabasa, okra, sitaw, talong.

Stage 2  — MobileViT-S unified deficiency expert (timm: mobilevit_s.cvnets_in1k)
           Classifies nutrient deficiency across crops into:
           healthy, nitrogen, phosphorus, potassium.
           All crop expert branches route directly to this unified model.

Both models receive the same 224×224 ImageNet-normalised tensor.
Stage 2 runs the unified expert model using the Stage-1 crop prediction context.

Checkpoint configuration (via environment variables)
----------------------------------------------------
HHC_STAGE1_CHECKPOINT          — path to ConvNeXt Stage-1 .pth file
                                  (default: backend/models/convnext_stage1.pth)
HHC_STAGE2_CHECKPOINT          — path to MobileViT Stage-2 unified expert .pth file
                                  (default: backend/models/mobilevit_stage2.pth)
HHC_STAGE2_LABELS              — comma-separated unified deficiency labels (optional)
HHC_EXPERT_<CROP>_LABELS       — comma-separated per-crop label overrides (optional)
HHC_DEVICE                     — "cpu" (default) or "cuda"
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

# Default checkpoint paths (configurable via HHC_STAGE1_CHECKPOINT and HHC_STAGE2_CHECKPOINT)
_DEFAULT_STAGE1_PATH = Path("backend/models/convnext_stage1.pth")
_DEFAULT_STAGE2_PATH = Path("backend/models/mobilevit_stage2.pth")

# Default per-crop label lists (must match ImageFolder alphabetical order used during training).
# Overridable via HHC_STAGE2_LABELS or HHC_EXPERT_<CROP>_LABELS env vars.
_DEFAULT_EXPERT_LABELS: dict[str, tuple[str, ...]] = {
    "ampalaya": ("healthy", "nitrogen", "phosphorus", "potassium"),
    "kalabasa": ("healthy", "nitrogen", "phosphorus", "potassium"),
    "okra":     ("healthy", "nitrogen", "phosphorus", "potassium"),
    "sitaw":    ("healthy", "nitrogen", "phosphorus", "potassium"),
    "talong":   ("healthy", "nitrogen", "phosphorus", "potassium"),
}

# Per-crop env-var names for optional label list overrides
_EXPERT_LABELS_VARS: dict[str, str] = {
    "ampalaya": "HHC_EXPERT_AMPALAYA_LABELS",
    "kalabasa": "HHC_EXPERT_KALABASA_LABELS",
    "okra":     "HHC_EXPERT_OKRA_LABELS",
    "sitaw":    "HHC_EXPERT_SITAW_LABELS",
    "talong":   "HHC_EXPERT_TALONG_LABELS",
}


# ---------------------------------------------------------------------------
# Preprocessing — unified for both stages
# ---------------------------------------------------------------------------

# Resize to 224×224, convert to float tensor in [0, 1], then ImageNet-normalise.
# ConvNeXt-Tiny and MobileViT-S are both fine-tuned on 224×224 inputs with
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

def _load_state_dict(model: nn.Module, path: Path, *, map_location: Any = "cpu") -> nn.Module:
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
    payload: Any = torch.load(path, map_location=map_location, weights_only=False)

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


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

class HHCInferencePipeline:
    """Two-stage HHC-VNDC inference pipeline.

    Stage 1 — ConvNeXt-Tiny: identifies the vegetable crop.
    Stage 2 — MobileViT-S per-crop expert: diagnoses the nutrient deficiency.

    Both stages consume the *same* preprocessed 224×224 tensor so the
    preprocessing cost is paid only once per request.  Stage 2 selects the
    expert model that corresponds to the Stage-1 crop prediction.

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
        deficiency_probabilities — {deficiency: prob} for all Stage-2 expert classes
    """

    def __init__(self) -> None:
        self.device = torch.device(
            os.getenv("HHC_DEVICE", "cuda" if torch.cuda.is_available() else "cpu")
        )
        self.stage1: nn.Module | None = None
        self.stage2: nn.Module | None = None
        # Per-crop expert models (routed to the unified MobileViT-S model): {crop_name: nn.Module}
        self.experts: dict[str, nn.Module] = {}
        # Per-crop label lists: {crop_name: tuple[str, ...]}
        self.expert_labels: dict[str, tuple[str, ...]] = {}
        self._load_error: str | None = None
        self._load_models()

    # ------------------------------------------------------------------
    # Public properties
    # ------------------------------------------------------------------

    @property
    def ready(self) -> bool:
        """True when Stage-1 and Stage-2 models loaded without error."""
        return (
            self._load_error is None
            and self.stage1 is not None
            and (self.stage2 is not None or len(self.experts) == len(VEGETABLES))
        )

    @property
    def load_error(self) -> str | None:
        """Human-readable error string, or None if models loaded cleanly."""
        return self._load_error

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _resolve_checkpoint(self, env_var: str, default: Path) -> Path:
        """Return the checkpoint path from an env var, falling back to *default*."""
        raw = os.getenv(env_var, "").strip()
        if raw:
            p = Path(raw)
            if p.exists():
                return p
            # Try relative to repo root if given path doesn't exist
            alt = Path(__file__).resolve().parent.parent / raw
            if alt.exists():
                return alt
            return p
        if default.exists():
            return default
        # If running from inside backend/ directory, try models/<filename>
        alt_models = Path("models") / default.name
        if alt_models.exists():
            return alt_models
        # Try relative to this file's parent directory
        alt_parent = Path(__file__).resolve().parent / "models" / default.name
        if alt_parent.exists():
            return alt_parent
        return default

    def _resolve_labels(self, crop: str) -> tuple[str, ...]:
        """Return label tuple for *crop* from env var or built-in default."""
        env_var = _EXPERT_LABELS_VARS.get(crop, "")
        raw = os.getenv(env_var, "").strip() if env_var else ""
        if raw:
            return tuple(lbl.strip() for lbl in raw.split(",") if lbl.strip())
        stage2_raw = os.getenv("HHC_STAGE2_LABELS", "").strip()
        if stage2_raw:
            return tuple(lbl.strip() for lbl in stage2_raw.split(",") if lbl.strip())
        return _DEFAULT_EXPERT_LABELS.get(crop, DEFICIENCIES)

    # ------------------------------------------------------------------
    # Model loading
    # ------------------------------------------------------------------

    def _load_models(self) -> None:
        """Instantiate and load Stage-1 ConvNeXt and Stage-2 MobileViT unified expert.

        Sets ``self._load_error`` on any failure so the server can surface a
        descriptive message without crashing at import time.
        """
        # ── Resolve core checkpoint paths ───────────────────────────────────────
        stage1_path = self._resolve_checkpoint(
            "HHC_STAGE1_CHECKPOINT", _DEFAULT_STAGE1_PATH
        )
        stage2_path = self._resolve_checkpoint(
            "HHC_STAGE2_CHECKPOINT", _DEFAULT_STAGE2_PATH
        )

        # ── Validate existence before loading ──────────────────────────────────
        missing: list[str] = []
        if not stage1_path.exists():
            missing.append(
                f"Stage 1 (ConvNeXt) checkpoint not found: '{stage1_path}' [set HHC_STAGE1_CHECKPOINT]"
            )
        if not stage2_path.exists():
            missing.append(
                f"Stage 2 (MobileViT) checkpoint not found: '{stage2_path}' [set HHC_STAGE2_CHECKPOINT]"
            )

        if missing:
            self._load_error = (
                "HHC checkpoints missing — set HHC_STAGE1_CHECKPOINT / "
                "HHC_STAGE2_CHECKPOINT or place files at the default paths:\n  "
                + "\n  ".join(missing)
            )
            logger.warning(self._load_error)
            return

        try:
            # ── Stage 1: ConvNeXt-Tiny (Crop Classifier) ────────────────────────
            logger.info("Loading Stage-1 (ConvNeXt-Tiny) from '%s' ...", stage1_path)
            s1 = timm.create_model(
                "convnext_tiny",
                pretrained=False,
                num_classes=len(VEGETABLES),
            )
            self.stage1 = (
                _load_state_dict(s1, stage1_path, map_location=str(self.device))
                .to(self.device)
                .eval()
            )
            logger.info(
                "Stage-1 ready — %d classes: %s", len(VEGETABLES), VEGETABLES
            )

            # ── Stage 2: MobileViT-S (Unified Deficiency Expert) ───────────────
            logger.info(
                "Loading Stage-2 unified expert (MobileViT-S, %d classes) from '%s' ...",
                len(DEFICIENCIES), stage2_path,
            )
            s2 = timm.create_model(
                "mobilevit_s.cvnets_in1k",
                pretrained=False,
                num_classes=len(DEFICIENCIES),
            )
            unified_expert = (
                _load_state_dict(s2, stage2_path, map_location=str(self.device))
                .to(self.device)
                .eval()
            )
            self.stage2 = unified_expert

            # Route all crop expert branches directly to the unified MobileViT expert
            for crop in VEGETABLES:
                labels = self._resolve_labels(crop)
                self.expert_labels[crop] = labels
                self.experts[crop] = unified_expert
                logger.info(
                    "Stage-2 crop expert '%s' routed to unified MobileViT-S — labels: %s",
                    crop, labels,
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
            vegetable_probabilities  — {vegetable: prob} for all 5 Stage-1 classes
            deficiency_probabilities — {deficiency: prob} for all Stage-2 expert classes
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

        # ── Stage 1: crop identification (ConvNeXt-Tiny) ──────────────────────
        veg_logits = self.stage1(tensor)                          # type: ignore[misc]
        veg_probs = torch.softmax(veg_logits, dim=1)[0]
        veg_idx = int(veg_probs.argmax())
        crop = VEGETABLES[veg_idx]
        confidence_stage1 = round(float(veg_probs[veg_idx]), 6)

        logger.info("Stage-1 → %s (%.1f%%)", crop, confidence_stage1 * 100)

        # ── Stage 2: expert deficiency diagnosis (MobileViT-S) ────────────────
        expert_model = self.experts[crop]
        labels = self.expert_labels[crop]

        def_logits = expert_model(tensor)                         # type: ignore[misc]
        def_probs = torch.softmax(def_logits, dim=1)[0]
        def_idx = int(def_probs.argmax())
        deficiency = labels[def_idx]
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
                for label, prob in zip(labels, def_probs)
            },
        }
