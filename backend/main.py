"""NutriLeaf HHC-VNDC FastAPI backend.

Endpoints
---------
GET  /              - liveness probe (no auth required)
GET  /api/health    - detailed health: model + supabase readiness
POST /predict       - multipart image upload -> HHC-VNDC two-stage diagnosis
"""
from __future__ import annotations

import logging
import mimetypes
import os
import uuid
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from supabase import Client, create_client

from hhc_pipeline import HHCInferencePipeline

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

load_dotenv()
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("nutrileaf")

# Supabase client (optional - prediction still works without it)
SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
# Prefer the service-role key so storage uploads bypass RLS.
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
    logger.warning(
        "SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not set - "
        "predictions will not be persisted to the database."
    )

# HHC inference pipeline (loaded at startup)
pipeline = HHCInferencePipeline()


# ---------------------------------------------------------------------------
# Lifespan
# ---------------------------------------------------------------------------


@asynccontextmanager
async def lifespan(_: FastAPI):
    if pipeline.ready:
        logger.info("HHC-VNDC pipeline is ready.")
    else:
        logger.warning("HHC-VNDC pipeline is NOT ready: %s", pipeline.load_error)
    yield


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(
    title="NutriLeaf HHC-VNDC Backend",
    version="3.0.0",
    description=(
        "Two-stage hierarchical computer-vision API for vegetable nutrient "
        "deficiency diagnosis (HHC-VNDC)."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@app.get("/", tags=["Health"])
async def root() -> dict[str, object]:
    """Liveness probe - always returns 200 if the server is up."""
    return {
        "status": "ok",
        "service": "NutriLeaf HHC-VNDC Backend",
        "version": "3.0.0",
        "model_ready": pipeline.ready,
    }


@app.get("/api/health", tags=["Health"])
async def health() -> dict[str, object]:
    """Detailed readiness check for the model and Supabase connection."""
    return {
        "status": "ok" if pipeline.ready else "degraded",
        "model_ready": pipeline.ready,
        "model_error": pipeline.load_error,
        "supabase_ready": supabase is not None,
    }


@app.post("/predict", tags=["Inference"])
async def predict(image: UploadFile = File(...)) -> dict[str, object]:
    """Run HHC-VNDC two-stage inference on an uploaded leaf image.

    Request
    -------
    multipart/form-data  ->  field name: image  (JPEG / PNG / WebP)

    Response (example)
    ------------------
    {
      "vegetable": "ampalaya",
      "vegetable_confidence": 0.942,
      "vegetable_probabilities": {"ampalaya": 0.942, "kalabasa": 0.03, ...},
      "diagnosed_deficiency": "nitrogen",
      "deficiency_confidence": 0.876,
      "deficiency_probabilities": {"healthy": 0.08, "nitrogen": 0.876, ...},
      "image_url": "https://.../diagnosis-images/abc123.jpg"
    }
    """
    if not image.filename:
        raise HTTPException(status_code=400, detail="No image file provided.")

    image_bytes = await image.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image file is empty.")

    if not pipeline.ready:
        raise HTTPException(
            status_code=503,
            detail=pipeline.load_error or "HHC pipeline is unavailable - check model checkpoints.",
        )

    try:
        prediction = pipeline.predict(image_bytes)

        if supabase is not None and os.path.exists('/tmp/debug_tensor.jpg'):
            try:
                with open('/tmp/debug_tensor.jpg', 'rb') as f:
                    debug_bytes = f.read()
                supabase.storage.from_(SUPABASE_BUCKET).upload(
                    "debug_tensor.jpg",
                    debug_bytes,
                    {"content-type": "image/jpeg", "upsert": "true"},
                )
                logger.info("Uploaded debug_tensor.jpg to Supabase.")
            except Exception:
                logger.exception("Failed to upload debug_tensor.jpg to Supabase.")

        image_url = await _persist_diagnosis(
            image_bytes,
            image.filename,
            image.content_type,
            prediction,
        )
        prediction["image_url"] = image_url
        return prediction

    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("HHC prediction failed for file '%s'", image.filename)
        raise HTTPException(
            status_code=500,
            detail="HHC inference failed - see server logs.",
        ) from exc


# ---------------------------------------------------------------------------
# Supabase persistence helpers
# ---------------------------------------------------------------------------


async def _persist_diagnosis(
    image_bytes: bytes,
    filename: str,
    content_type: str | None,
    prediction: dict[str, object],
) -> str | None:
    """Upload image to Supabase Storage and insert a row into diagnoses_history.

    Returns the public image URL, or None if Supabase is not configured.
    Failures are logged and swallowed so a DB error never breaks a prediction.
    """
    if supabase is None:
        logger.debug("Supabase not configured - skipping persistence.")
        return None

    try:
        # 1. Determine storage path & MIME type
        extension = os.path.splitext(filename)[1].lower() or ".jpg"
        storage_path = f"{uuid.uuid4().hex}{extension}"
        mime_type = content_type or mimetypes.guess_type(filename)[0] or "image/jpeg"

        # 2. Upload image bytes to Supabase Storage
        supabase.storage.from_(SUPABASE_BUCKET).upload(
            storage_path,
            image_bytes,
            {"content-type": mime_type, "upsert": "false"},
        )
        image_url: str = supabase.storage.from_(SUPABASE_BUCKET).get_public_url(storage_path)
        logger.info("Image uploaded to Storage: %s", storage_path)

        # 3. Insert diagnosis record into PostgreSQL via Supabase client
        supabase.table("diagnoses_history").insert(
            {
                "vegetable": str(prediction["vegetable"]),
                # pyrefly: ignore [bad-argument-type]
                "vegetable_confidence": float(prediction["vegetable_confidence"]),
                "diagnosed_deficiency": str(prediction["diagnosed_deficiency"]),
                # pyrefly: ignore [bad-argument-type]
                "deficiency_confidence": float(prediction["deficiency_confidence"]),
                "image_url": image_url,
                "storage_path": storage_path,
                # user_id omitted intentionally; the Flutter client's
                # authenticated Supabase session can supply it separately
                # when RLS per-user filtering is desired.
            }
        ).execute()
        logger.info(
            "Diagnosis saved to DB (vegetable=%s, deficiency=%s)",
            prediction["vegetable"],
            prediction["diagnosed_deficiency"],
        )
        return image_url

    except Exception:
        logger.exception("Supabase persistence failed - returning prediction without image_url.")
        return None
