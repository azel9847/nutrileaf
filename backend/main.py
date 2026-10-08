"""NutriLeaf HHC-VNDC FastAPI backend (ConvNeXt-Tiny -> MobileViT-S).

Endpoints
---------
GET  /              - liveness probe
GET  /api/health    - model + supabase readiness
POST /predict       - multipart image upload -> two-stage diagnosis (JSON)
"""
from __future__ import annotations

import io
import logging
import mimetypes
import os
import uuid
from contextlib import asynccontextmanager
from pathlib import Path

import timm
import torch
import torch.nn.functional as F
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, ImageOps, UnidentifiedImageError
from supabase import Client, create_client
from torchvision import transforms

# ---------------------------------------------------------------------------
# Bootstrap / configuration
# ---------------------------------------------------------------------------

load_dotenv()
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("nutrileaf")

BASE_DIR = Path(__file__).resolve().parent
MODELS_DIR = BASE_DIR / "models"

STAGE1_WEIGHTS = Path(os.getenv("STAGE1_WEIGHTS", MODELS_DIR / "convnext_stage1.pth"))
STAGE2_WEIGHTS = Path(os.getenv("STAGE2_WEIGHTS", MODELS_DIR / "mobilevit_stage2.pth"))

# Alphabetically sorted (matches PyTorch ImageFolder index order).
STAGE1_CLASSES = ["Ampalaya", "Kalabasa", "Okra", "Sitaw", "Talong"]
DEFICIENCY_CLASSES = ["Healthy", "Nitrogen", "Phosphorus", "Potassium"]

KALABASA_IDX = STAGE1_CLASSES.index("Kalabasa")
PHOSPHORUS_IDX = DEFICIENCY_CLASSES.index("Phosphorus")

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Supabase (optional - prediction still works without it)
SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
SUPABASE_KEY = os.getenv(
    "SUPABASE_SERVICE_ROLE_KEY",
    os.getenv("SUPABASE_ANON_KEY", os.getenv("SUPABASE_KEY", "")),
).strip()
SUPABASE_BUCKET = os.getenv("SUPABASE_STORAGE_BUCKET", "diagnosis-images")

supabase: Client | None = None
if SUPABASE_URL and SUPABASE_KEY:
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        logger.info("Supabase client initialised (bucket: %s)", SUPABASE_BUCKET)
    except Exception:
        logger.exception("Failed to initialise Supabase client - persistence disabled")
else:
    logger.warning("Supabase not configured - predictions will not be persisted.")

# ---------------------------------------------------------------------------
# Preprocessing (shared by both stages)
# ---------------------------------------------------------------------------

inference_transforms = transforms.Compose(
    [
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ]
)

# ---------------------------------------------------------------------------
# Model loading
# ---------------------------------------------------------------------------

stage1_model: torch.nn.Module | None = None
stage2_model: torch.nn.Module | None = None
load_error: str | None = None


def _load_model(arch: str, num_classes: int, weights_path: Path) -> torch.nn.Module:
    """Build *arch* (pretrained=False) and load a local .pth checkpoint."""
    if not weights_path.is_file():
        raise FileNotFoundError(f"Weights file not found: {weights_path}")

    model = timm.create_model(arch, pretrained=False, num_classes=num_classes)

    checkpoint = torch.load(weights_path, map_location="cpu")
    # Unwrap common training-checkpoint containers.
    if isinstance(checkpoint, dict):
        for key in ("state_dict", "model_state_dict", "model"):
            if key in checkpoint and isinstance(checkpoint[key], dict):
                checkpoint = checkpoint[key]
                break
    if isinstance(checkpoint, torch.nn.Module):
        checkpoint = checkpoint.state_dict()

    # Strip DataParallel / Lightning prefixes.
    state_dict = {
        (k[len("module."):] if k.startswith("module.") else k): v
        for k, v in checkpoint.items()
    }

    result = model.load_state_dict(state_dict, strict=False)
    if result.missing_keys or result.unexpected_keys:
        logger.warning(
            "%s: %d missing / %d unexpected keys when loading %s",
            arch, len(result.missing_keys), len(result.unexpected_keys), weights_path.name,
        )

    return model.to(DEVICE).eval()


def load_models() -> None:
    global stage1_model, stage2_model, load_error
    try:
        stage1_model = _load_model("convnext_tiny", len(STAGE1_CLASSES), STAGE1_WEIGHTS)
        stage2_model = _load_model("mobilevit_s", len(DEFICIENCY_CLASSES), STAGE2_WEIGHTS)
        load_error = None
        logger.info("HHC-VNDC models loaded on %s.", DEVICE)
    except Exception as exc:
        stage1_model = stage2_model = None
        load_error = f"{type(exc).__name__}: {exc}"
        logger.exception("Failed to load HHC-VNDC models")


def models_ready() -> bool:
    return stage1_model is not None and stage2_model is not None


# ---------------------------------------------------------------------------
# Inference
# ---------------------------------------------------------------------------


@torch.inference_mode()
def run_pipeline(image_bytes: bytes) -> dict[str, object]:
    s1, s2 = stage1_model, stage2_model
    if s1 is None or s2 is None:
        raise HTTPException(status_code=503, detail=load_error or "Models unavailable.")

    try:
        image = Image.open(io.BytesIO(image_bytes))
        image = ImageOps.exif_transpose(image).convert("RGB")
    except (UnidentifiedImageError, OSError) as exc:
        raise HTTPException(status_code=400, detail="Invalid or unsupported image file.") from exc

    tensor = inference_transforms(image).unsqueeze(0).to(DEVICE)

    # Stage 1 - crop identification
    crop_probs = F.softmax(s1(tensor), dim=1)[0]
    crop_idx = int(crop_probs.argmax())
    crop_conf = float(crop_probs[crop_idx])
    crop = STAGE1_CLASSES[crop_idx]

    # Stage 2 - nutrient deficiency diagnosis
    def_probs = F.softmax(s2(tensor), dim=1)[0]

    # Kalabasa has no Phosphorus class in the dataset: fall back to the
    # next-highest probability class.
    if crop_idx == KALABASA_IDX:
        masked = def_probs.clone()
        masked[PHOSPHORUS_IDX] = float("-inf")
        def_idx = int(masked.argmax())
    else:
        def_idx = int(def_probs.argmax())

    return {
        "crop": crop,
        "crop_confidence": round(crop_conf, 4),
        "deficiency": DEFICIENCY_CLASSES[def_idx],
        "deficiency_confidence": round(float(def_probs[def_idx]), 4),
    }


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------


@asynccontextmanager
async def lifespan(_: FastAPI):
    load_models()
    yield


app = FastAPI(
    title="NutriLeaf HHC-VNDC Backend",
    version="4.0.0",
    description="Two-stage (ConvNeXt-Tiny + MobileViT-S) vegetable nutrient deficiency diagnosis.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["Health"])
async def root() -> dict[str, object]:
    return {
        "status": "ok",
        "service": "NutriLeaf HHC-VNDC Backend",
        "version": "4.0.0",
        "model_ready": models_ready(),
    }


@app.get("/api/health", tags=["Health"])
async def health() -> dict[str, object]:
    return {
        "status": "ok" if models_ready() else "degraded",
        "model_ready": models_ready(),
        "model_error": load_error,
        "supabase_ready": supabase is not None,
    }


@app.post("/predict", tags=["Inference"])
async def predict(image: UploadFile = File(...)) -> dict[str, object]:
    """Run two-stage inference on an uploaded leaf image.

    Response:
        {"crop": "Eggplant", "crop_confidence": 0.998,
         "deficiency": "Potassium", "deficiency_confidence": 0.925,
         "image_url": "https://..." | null}
    """
    if not image.filename:
        raise HTTPException(status_code=400, detail="No image file provided.")

    image_bytes = await image.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image file is empty.")

    if not models_ready():
        raise HTTPException(
            status_code=503,
            detail=load_error or "Models unavailable - check weight files.",
        )

    try:
        prediction = run_pipeline(image_bytes)
        prediction["image_url"] = await _persist_diagnosis(
            image_bytes, image.filename, image.content_type, prediction
        )
        return prediction
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("Prediction failed for file '%s'", image.filename)
        raise HTTPException(status_code=500, detail="Inference failed - see server logs.") from exc


# ---------------------------------------------------------------------------
# Supabase persistence
# ---------------------------------------------------------------------------


async def _persist_diagnosis(
    image_bytes: bytes,
    filename: str,
    content_type: str | None,
    prediction: dict[str, object],
) -> str | None:
    """Upload the image and log the diagnosis. Never raises."""
    if supabase is None:
        return None

    try:
        extension = os.path.splitext(filename)[1].lower() or ".jpg"
        storage_path = f"{uuid.uuid4().hex}{extension}"
        mime_type = content_type or mimetypes.guess_type(filename)[0] or "image/jpeg"

        supabase.storage.from_(SUPABASE_BUCKET).upload(
            storage_path,
            image_bytes,
            {"content-type": mime_type, "upsert": "false"},
        )
        image_url: str = supabase.storage.from_(SUPABASE_BUCKET).get_public_url(storage_path)

        supabase.table("diagnoses_history").insert(
            {
                "vegetable": str(prediction["crop"]),
                "vegetable_confidence": float(prediction["crop_confidence"]),  # type: ignore[arg-type]
                "diagnosed_deficiency": str(prediction["deficiency"]),
                "deficiency_confidence": float(prediction["deficiency_confidence"]),  # type: ignore[arg-type]
                "image_url": image_url,
                "storage_path": storage_path,
            }
        ).execute()
        return image_url
    except Exception:
        logger.exception("Supabase persistence failed - returning prediction without image_url.")
        return None


# ---------------------------------------------------------------------------
# Server startup (Cloud Run / local)
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)