"""HHC-VNDC hierarchical inference pipeline.

Architecture
------------
Stage 1  — EfficientNetV2-S (timm, features_only) + Swin-T (timm) with CBAM
           attention fusion.  Classifies leaf images into one of 5 vegetables:
           ampalaya, kalabasa, okra, sitaw, talong.

Stage 2  — Five per-vegetable specialist models with the same architecture.
           Routed by Stage 1 and classified into:
           healthy, nitrogen, phosphorus, potassium.

Fusion details
--------------
  CNN  : full timm EfficientNetV2-S (num_classes=0, global_pool='avg')
         → conv_head (256→1280) → AdaptiveAvgPool2d(1) → 1280
  Swin : timm swin_tiny_patch4_window7_224 (num_classes=0) → 768
  Cat  : [1280, 768] → 2048
  FC   : Linear(2048, 512) + ReLU
  CBAM : ChannelAttention(bias=False) + SpatialAttention(bias=False) on 2048-dim
  Head : Linear(512, num_classes)

Checkpoint configuration (via environment variables)
----------------------------------------------------
HHC_STAGE1_CHECKPOINT           — path to Stage-1 .pt / .pth file
HHC_EXPERT_AMPALAYA_CHECKPOINT  — expert for ampalaya
HHC_EXPERT_KALABASA_CHECKPOINT  — expert for kalabasa
HHC_EXPERT_OKRA_CHECKPOINT      — expert for okra
HHC_EXPERT_SITAW_CHECKPOINT     — expert for sitaw
HHC_EXPERT_TALONG_CHECKPOINT    — expert for talong
HHC_DEVICE                      — "cpu" (default) or "cuda"
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
import torchvision.utils as vutils

logger = logging.getLogger("nutrileaf.hhc")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

VEGETABLES: tuple[str, ...] = ("ampalaya", "kalabasa", "okra", "sitaw", "talong")
DEFICIENCIES: tuple[str, ...] = ("healthy", "nitrogen", "phosphorus", "potassium")

# Fused feature dimension: EfficientNetV2-S conv_head (1280) + Swin-T (768) = 2048
_FUSED_DIM: int = 2048
_CNN_OUT_DIM: int = 1280  # timm EfficientNetV2-S global_pool='avg' output
_SWIN_DIM: int = 768      # swin_tiny_patch4_window7_224 num_classes=0 output
_FC_DIM: int = 512        # FC projection: 2048 → 512 before CBAM + classifier


# ---------------------------------------------------------------------------
# CBAM Attention (matches checkpoint key naming exactly)
# ---------------------------------------------------------------------------

class _ChannelAttention(nn.Module):
    """Channel Attention Module.

    Saved keys: cbam.ca.fc.{0,2}.weight  (no bias — bias=False)
    """

    def __init__(self, channels: int, reduction: int = 16) -> None:
        super().__init__()
        r = max(channels // reduction, 1)
        self.fc = nn.Sequential(
            nn.Conv2d(channels, r, 1, bias=False),
            nn.ReLU(inplace=True),
            nn.Conv2d(r, channels, 1, bias=False),
            nn.Sigmoid(),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        gap = x.mean((2, 3), keepdim=True)   # [N, C, 1, 1]
        return x * self.fc(gap)


class _SpatialAttention(nn.Module):
    """Spatial Attention Module.

    Saved keys: cbam.sa.conv.weight  (no bias — bias=False)
    """

    def __init__(self) -> None:
        super().__init__()
        self.conv = nn.Conv2d(2, 1, kernel_size=7, padding=3, bias=False)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        avg_out = x.mean(dim=1, keepdim=True)
        max_out = x.max(dim=1, keepdim=True)[0]
        attn = torch.sigmoid(self.conv(torch.cat([avg_out, max_out], dim=1)))
        return x * attn


class _CBAM(nn.Module):
    """Convolutional Block Attention Module (channel + spatial)."""

    def __init__(self, channels: int, reduction: int = 16) -> None:
        super().__init__()
        self.ca = _ChannelAttention(channels, reduction)
        self.sa = _SpatialAttention()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.sa(self.ca(x))


# ---------------------------------------------------------------------------
# HHC Model (shared for Stage 1 and Stage 2)
# ---------------------------------------------------------------------------

class HHCModel(nn.Module):
    """EfficientNetV2-S + Swin-T + CBAM fusion classifier.

    Used for both pipeline stages:
      - Stage 1: num_classes=5  (vegetable identification)
      - Stage 2: num_classes=4  (nutrient deficiency per vegetable)

    Forward pass
    ------------
    1. CNN  : full timm EfficientNetV2-S (global_pool='avg') → [N, 1280]
    2. Swin : timm Swin-T (num_classes=0) → [N, 768]
    3. Cat  : → [N, 2048], reshape to [N, 2048, 1, 1]
    4. FC   : Linear(2048, 512) + ReLU → [N, 512, 1, 1]
    5. CBAM : channel + spatial attention on the 2048-dim tensor (applied
              before FC in training; fc projects the attended features)
    6. Head : Linear(512, num_classes)
    """

    def __init__(self, num_classes: int) -> None:
        super().__init__()
        # Full EfficientNetV2-S including conv_head (256→1280) and bn2.
        # global_pool='avg' performs AdaptiveAvgPool2d(1) + flatten internally.
        self.cnn = timm.create_model(
            "efficientnetv2_s",
            pretrained=False,
            num_classes=0,
            global_pool="avg",
        )
        # Swin-T — returns [N, 768] pooled feature vector.
        self.swin = timm.create_model(
            "swin_tiny_patch4_window7_224",
            pretrained=False,
            num_classes=0,
        )
        # FC projection applied after concatenation and CBAM.
        self.fc = nn.Linear(_FUSED_DIM, _FC_DIM)
        # CBAM operates on the 2048-dim fused representation.
        self.cbam = _CBAM(_FUSED_DIM)
        # Plain linear head (no Dropout wrapper in retrained checkpoints).
        self.classifier = nn.Linear(_FC_DIM, num_classes)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # CNN branch → [N, 1280]
        cnn_feat = self.cnn(x)

        # Swin-T branch → [N, 768]
        swin_feat = self.swin(x)

        # Fuse → [N, 2048, 1, 1]
        fused = torch.cat([cnn_feat, swin_feat], dim=1).unsqueeze(-1).unsqueeze(-1)

        # CBAM attention → [N, 2048, 1, 1]
        fused = self.cbam(fused)

        # FC projection → [N, 512]
        projected = torch.relu(self.fc(fused.flatten(1)))

        return self.classifier(projected)


# ---------------------------------------------------------------------------
# Checkpoint loading helpers
# ---------------------------------------------------------------------------

def _checkpoint_path(env_var: str) -> Path | None:
    """Return a Path from an env var, or None if the var is unset / empty."""
    value = os.getenv(env_var, "").strip()
    return Path(value) if value else None


def _num_classes_from_checkpoint(path: Path) -> int:
    """Read classifier.weight from a checkpoint and return its num_classes."""
    payload: Any = torch.load(path, map_location="cpu", weights_only=False)
    if isinstance(payload, nn.Module):
        return next(p for name, p in payload.named_parameters()
                    if "classifier" in name and p.ndim == 2).shape[0]
    if isinstance(payload, dict):
        sd = payload.get("state_dict", payload.get("model_state_dict", payload))
        sd = {str(k).removeprefix("module."): v for k, v in sd.items()}
        return int(sd["classifier.weight"].shape[0])
    raise ValueError(f"Cannot determine num_classes from checkpoint at '{path}'.")


def _expert_labels_from_env(veg: str, path: Path) -> tuple[str, ...]:
    """Read the explicit class label list for an expert from its env var.

    Reads ``HHC_EXPERT_<VEG>_LABELS`` (comma-separated, e.g.
    ``healthy,nitrogen,potassium``) and validates that the count matches the
    checkpoint's ``classifier.weight`` shape.

    Raises
    ------
    ValueError
        If the env var is missing or the label count does not match the
        checkpoint's output dimension.
    """
    env_var = f"HHC_EXPERT_{veg.upper()}_LABELS"
    raw = os.getenv(env_var, "").strip()
    if not raw:
        raise ValueError(
            f"{env_var} is not set.  Add it to .env with the comma-separated "
            f"deficiency labels in the same order used during training "
            f"(e.g. HHC_EXPERT_{veg.upper()}_LABELS=healthy,nitrogen,potassium)."
        )
    labels = tuple(label.strip() for label in raw.split(",") if label.strip())

    # Cross-check against the checkpoint's output dimension.
    num_cls = _num_classes_from_checkpoint(path)
    if len(labels) != num_cls:
        raise ValueError(
            f"{env_var} declares {len(labels)} label(s) ({labels}) but the "
            f"checkpoint '{path.name}' has classifier.weight with "
            f"{num_cls} output(s).  Fix the env var to match."
        )

    # Warn about any label not in the canonical DEFICIENCIES list.
    unknown = [lbl for lbl in labels if lbl not in DEFICIENCIES]
    if unknown:
        logger.warning(
            "Expert '%s': label(s) %s not in canonical DEFICIENCIES %s",
            veg, unknown, DEFICIENCIES,
        )
    return labels


def _load_checkpoint(model: nn.Module, path: Path) -> nn.Module:
    """Load a checkpoint into *model* and return it (strict=True).

    Handles three checkpoint formats:
    1. Serialised nn.Module   — returned as-is after device mapping.
    2. Raw state-dict         — loaded directly.
    3. Training checkpoint    — state_dict extracted from "state_dict" /
                                "model_state_dict" key.
    """
    payload: Any = torch.load(path, map_location="cpu", weights_only=False)

    if isinstance(payload, nn.Module):
        return payload

    if isinstance(payload, dict):
        state_dict = payload.get("state_dict", payload.get("model_state_dict", payload))
    else:
        raise ValueError(
            f"Unsupported checkpoint format at '{path}'. "
            "Expected nn.Module, state_dict, or training checkpoint dict."
        )

    # Strip "module." prefix added by DataParallel / DistributedDataParallel
    cleaned = {str(k).removeprefix("module."): v for k, v in state_dict.items()}

    missing, unexpected = model.load_state_dict(cleaned, strict=False)
    if missing:
        logger.warning("Checkpoint '%s': %d missing keys", path.name, len(missing))
        logger.debug("Missing keys: %s", missing)
    if unexpected:
        logger.warning("Checkpoint '%s': %d unexpected keys", path.name, len(unexpected))
        logger.debug("Unexpected keys: %s", unexpected)

    return model


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

class HHCInferencePipeline:
    """Two-stage HHC-VNDC inference pipeline.

    Usage::

        pipeline = HHCInferencePipeline()
        if pipeline.ready:
            result = pipeline.predict(image_bytes)

    ``predict`` returns a dict with keys:
        vegetable, vegetable_confidence, vegetable_probabilities,
        diagnosed_deficiency, deficiency_confidence, deficiency_probabilities
    """

    # ---------------------------------------------------------------------------
    # ImageNet eval preprocessing — must exactly match training transforms.
    #
    # Step-by-step rationale:
    #   1. Resize(256, BICUBIC)   — scale the *shorter* edge to 256 px while
    #      preserving the original aspect ratio.  Using a scalar (not a tuple)
    #      tells torchvision to resize only the short side, keeping the other
    #      proportional.  BICUBIC matches the interpolation used by the
    #      EfficientNetV2-S training pipeline (torchvision default is BILINEAR
    #      which shifts the pixel distribution and degrades accuracy).
    #
    #   2. CenterCrop(224)        — extract a centred 224×224 square.  This is
    #      the standard ImageNet eval crop (avoids the aspect-ratio distortion
    #      caused by directly resizing to (224, 224) with a 2-tuple).
    #
    #   3. ToTensor()             — converts PIL HWC uint8 [0–255] to a CHW
    #      float32 tensor in [0.0, 1.0].  No manual division needed.
    #
    #   4. Normalize(mean, std)   — subtracts ImageNet channel means and divides
    #      by standard deviations so the distribution matches what both
    #      EfficientNetV2-S and Swin-T were pre-trained on.
    # ---------------------------------------------------------------------------
    _TRANSFORM = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225],
        ),
    ])

    def __init__(self) -> None:
        self.device = torch.device(os.getenv("HHC_DEVICE", "cpu"))
        self.stage1: nn.Module | None = None
        self.experts: dict[str, nn.Module] = {}
        self._load_error: str | None = None
        self._load_models()

    # ------------------------------------------------------------------
    # Public properties
    # ------------------------------------------------------------------

    @property
    def ready(self) -> bool:
        """True when all 6 models loaded without error."""
        return (
            self._load_error is None
            and self.stage1 is not None
            and len(self.experts) == len(VEGETABLES)
        )

    @property
    def load_error(self) -> str | None:
        """Human-readable error string, or None if models loaded fine."""
        return self._load_error

    # ------------------------------------------------------------------
    # Model loading
    # ------------------------------------------------------------------

    def _load_models(self) -> None:
        """Discover checkpoint paths from env vars and load all models.

        Sets self._load_error on any failure so callers can surface the
        message without crashing the server.
        """
        stage1_path = _checkpoint_path("HHC_STAGE1_CHECKPOINT")
        expert_paths: dict[str, Path | None] = {
            veg: _checkpoint_path(f"HHC_EXPERT_{veg.upper()}_CHECKPOINT")
            for veg in VEGETABLES
        }

        missing_vars: list[str] = []

        if stage1_path is None:
            missing_vars.append("HHC_STAGE1_CHECKPOINT (not set)")
        elif not stage1_path.exists():
            missing_vars.append(f"HHC_STAGE1_CHECKPOINT -> '{stage1_path}' (not found)")

        for veg, path in expert_paths.items():
            env_var = f"HHC_EXPERT_{veg.upper()}_CHECKPOINT"
            if path is None:
                missing_vars.append(f"{env_var} (not set)")
            elif not path.exists():
                missing_vars.append(f"{env_var} -> '{path}' (not found)")

        if missing_vars:
            self._load_error = (
                "HHC checkpoints missing or not configured:\n  " + "\n  ".join(missing_vars)
            )
            logger.warning(self._load_error)
            return

        try:
            logger.info("Loading Stage-1 checkpoint from '%s' ...", stage1_path)
            self.stage1 = (
                _load_checkpoint(HHCModel(num_classes=len(VEGETABLES)), stage1_path)  # type: ignore[arg-type]
                .to(self.device)
                .eval()
            )

            logger.info("Loading %d expert checkpoints ...", len(VEGETABLES))
            self._expert_labels: dict[str, tuple[str, ...]] = {}
            self.experts = {}
            for veg, path in expert_paths.items():
                # Read explicit label list from env — this is the only reliable
                # source since PyTorch checkpoints store no label metadata.
                labels = _expert_labels_from_env(veg, path)  # type: ignore[arg-type]
                self._expert_labels[veg] = labels
                logger.info(
                    "Expert '%s': %d classes %s", veg, len(labels), labels
                )
                self.experts[veg] = (
                    _load_checkpoint(HHCModel(num_classes=len(labels)), path)  # type: ignore[arg-type]
                    .to(self.device)
                    .eval()
                )
            logger.info(
                "All HHC models loaded on device '%s'. Vegetables: %s",
                self.device,
                VEGETABLES,
            )
        except Exception as exc:
            self._load_error = f"HHC checkpoint loading failed: {exc}"
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

        Returns
        -------
        dict with the following keys:
            vegetable                — predicted vegetable name (str)
            vegetable_confidence     — top class softmax probability (float)
            vegetable_probabilities  — {vegetable: prob} for all 5 classes
            diagnosed_deficiency     — predicted deficiency label (str)
            deficiency_confidence    — top class softmax probability (float)
            deficiency_probabilities — {deficiency: prob} for all 4 classes
        """
        if not self.ready:
            raise RuntimeError(self.load_error or "HHC pipeline is unavailable.")

        # --- Preprocess image ------------------------------------------------
        # PIL load forces RGB (avoids OpenCV BGR channel flip).
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        # Honour EXIF rotation flags from smartphone cameras so the model
        # always receives an upright image regardless of capture orientation.
        image = ImageOps.exif_transpose(image)
        tensor = self._TRANSFORM(image).unsqueeze(0).to(self.device)

        print("original_image.size:", image.size)
        print("tensor.shape:", tensor.shape)
        vutils.save_image(tensor, '/tmp/debug_tensor.jpg', normalize=True)

        # --- Stage 1: vegetable classification -------------------------------
        veg_logits = self.stage1(tensor)  # type: ignore[misc]
        veg_probs = torch.softmax(veg_logits, dim=1)[0]
        veg_idx = int(veg_probs.argmax())
        vegetable = VEGETABLES[veg_idx]
        logger.debug(
            "Stage-1 -> %s (%.1f%%)", vegetable, float(veg_probs[veg_idx]) * 100
        )

        # --- Stage 2: expert deficiency classification -----------------------
        expert = self.experts[vegetable]
        # Use the labels this specific expert was trained on (may be a subset
        # of DEFICIENCIES, e.g. 3 classes if 'healthy' was absent in training).
        expert_labels = self._expert_labels.get(vegetable, DEFICIENCIES)

        def_logits = expert(tensor)
        def_probs = torch.softmax(def_logits, dim=1)[0]
        def_idx = int(def_probs.argmax())
        deficiency = expert_labels[def_idx]
        logger.debug(
            "Stage-2 (%s expert) -> %s (%.1f%%) [%d classes]",
            vegetable,
            deficiency,
            float(def_probs[def_idx]) * 100,
            len(expert_labels),
        )

        return {
            "vegetable": vegetable,
            "vegetable_confidence": round(float(veg_probs[veg_idx]), 6),
            "vegetable_probabilities": {
                label: round(float(prob), 6)
                for label, prob in zip(VEGETABLES, veg_probs)
            },
            "diagnosed_deficiency": deficiency,
            "deficiency_confidence": round(float(def_probs[def_idx]), 6),
            "deficiency_probabilities": {
                label: round(float(prob), 6)
                for label, prob in zip(expert_labels, def_probs)
            },
        }
