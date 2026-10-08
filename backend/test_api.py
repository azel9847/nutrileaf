"""Smoke-test script for the NutriLeaf HHC-VNDC backend.

Usage
-----
Run from inside the backend/ directory with the venv active:

    python test_api.py [--host http://127.0.0.1:8000] [image_path]

Tests performed
---------------
1. GET /          — liveness check
2. GET /api/health — model + Supabase readiness
3. POST /predict  — inference on a sample image (green square if none supplied)
4. POST /predict  — empty upload (expects 400)
"""
from __future__ import annotations

import argparse
import io
import json
import sys
import urllib.error
import urllib.request
from typing import Any

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def get(url: str) -> tuple[int, Any]:
    try:
        res = urllib.request.urlopen(url, timeout=30)
        return res.status, json.loads(res.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def post_multipart(url: str, image_bytes: bytes, filename: str = "leaf.jpg") -> tuple[int, Any]:
    """Send a multipart/form-data POST with a single 'image' field."""
    boundary = "----NutriLeafTestBoundary"
    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="image"; filename="{filename}"\r\n'
        f"Content-Type: image/jpeg\r\n\r\n"
    ).encode() + image_bytes + f"\r\n--{boundary}--\r\n".encode()

    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "Content-Length": str(len(body)),
        },
    )
    try:
        res = urllib.request.urlopen(req, timeout=120)
        return res.status, json.loads(res.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def _make_green_jpeg() -> bytes:
    """Generate a minimal green 64x64 JPEG for testing without PIL."""
    try:
        from PIL import Image  # type: ignore[import]
        buf = io.BytesIO()
        img = Image.new("RGB", (64, 64), color=(50, 180, 50))
        img.save(buf, format="JPEG")
        return buf.getvalue()
    except ImportError:
        # Fallback: a tiny valid JPEG (1x1 green pixel, SOI+APPn+SOF+…)
        # This is a well-formed 1x1 green JPEG in raw bytes.
        return bytes.fromhex(
            "FFD8FFE000104A46494600010100000100010000"
            "FFDB004300080606070605080707070909080A0C140D0C0B0B0C1912130F"
            "141D1A1F1E1D1A1C1C20242E2720222C231C1C2837292C30313434341F27"
            "39"
            "3D38323C2E333432FFDB00430109090C0B0C180D0D1832211C213232323232"
            "323232323232323232323232323232323232323232323232323232323232"
            "32323232323232323232323232323232FFC00011080001000103012200021"
            "101031101FFC4001F0000010501010101010100000000000000000102030405"
            "060708090A0BFFC400B5100002010303020403050504040000017D010203"
            "00041105122131410613516107227114328191A1082342B1C11552D1F0"
            "24336272829192A484C495253627374858687959697A2A3A4A5A6A7A8A9AA"
            "B2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE1E2"
            "E3E4E5E6E7E8E9EAF1F2F3F4F5F6F7F8F9FAFFC4001F01000301010101"
            "0101010100000000000000010203040506070809"
            "0A0BFFC400B5110002010204040304070504040001027700010203110405"
            "21314106136151071322328108144291A1B1C109233352F0156272D10A162"
            "434E125F11718191A262728292A353637383"
            "9"
            "3A434445464748494A535455565758595A636465666768696A737475767778"
            "797A838485868788898A929394959697989"
            "9A"
            "A2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9CAD2D3"
            "D4D5D6D7D8D9DAE2E3E4E5E6E7E8E9EAF2F3F4F5F6F7F8F9FAFFDA000C"
            "03010002110311003F00F5FFFD9"
        )


# ---------------------------------------------------------------------------
# Test runner
# ---------------------------------------------------------------------------


def run_tests(host: str, image_path: str | None) -> None:
    ok = True
    sep = "-" * 60

    print(f"\n{'='*60}")
    print(f"  NutriLeaf HHC-VNDC Backend Smoke Tests")
    print(f"  Target: {host}")
    print(f"{'='*60}\n")

    # ── 1. Liveness ──────────────────────────────────────────────────
    print("TEST 1 — GET /  (liveness)")
    status, body = get(f"{host}/")
    print(f"  Status : {status}")
    print(f"  Body   : {json.dumps(body, indent=4)}")
    assert status == 200, f"Expected 200, got {status}"
    print("  ✅ PASS\n")

    # ── 2. Health ────────────────────────────────────────────────────
    print("TEST 2 — GET /api/health  (readiness)")
    status, body = get(f"{host}/api/health")
    print(f"  Status       : {status}")
    print(f"  model_ready  : {body.get('model_ready')}")
    print(f"  model_error  : {body.get('model_error')}")
    print(f"  supabase_ready: {body.get('supabase_ready')}")
    assert status == 200, f"Expected 200, got {status}"
    if not body.get("model_ready"):
        print(f"  ⚠️  WARNING: model not ready — skipping /predict tests\n")
        print("  (Set HHC_*_CHECKPOINT env vars and restart the server.)")
        return
    print("  ✅ PASS\n")

    # ── 3. Valid prediction ──────────────────────────────────────────
    print("TEST 3 — POST /predict  (valid image)")
    if image_path:
        with open(image_path, "rb") as f:
            img_bytes = f.read()
        filename = image_path.split("/")[-1].split("\\")[-1]
    else:
        img_bytes = _make_green_jpeg()
        filename = "test_green.jpg"
        print(f"  (No image path provided — using synthetic {filename})")

    status, body = post_multipart(f"{host}/predict", img_bytes, filename)
    print(f"  Status                : {status}")
    if status == 200:
        print(f" crop                 : {body.get('crop')} ({body.get('crop_confidence', 0)*100:.1f}%)")
        print(f" deficiency           : {body.get('deficiency')} ({body.get('deficiency_confidence', 0)*100:.1f}%)")
        print(f" image_url            : {body.get('image_url')}")
        assert "crop" in body
        assert "deficiency" in body
        assert "crop_confidence" in body
        assert "deficiency_confidence" in body
        print("  ✅ PASS\n")
    else:
        print(f"  Body   : {json.dumps(body, indent=4)}")
        print("  ❌ FAIL\n")
        ok = False

    # ── 4. Empty upload → 400 ───────────────────────────────────────
    print("TEST 4 — POST /predict  (empty bytes, expect 400)")
    status, body = post_multipart(f"{host}/predict", b"", "empty.jpg")
    print(f"  Status : {status}")
    print(f"  detail : {body.get('detail')}")
    assert status == 400, f"Expected 400, got {status}"
    print("  ✅ PASS\n")

    print(sep)
    if ok:
        print("All tests passed! 🎉")
    else:
        print("Some tests FAILED. See output above.")
        sys.exit(1)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NutriLeaf HHC-VNDC API smoke tests")
    parser.add_argument("--host", default="http://127.0.0.1:8000", help="Backend base URL")
    parser.add_argument("image", nargs="?", help="Optional path to a real leaf image")
    args = parser.parse_args()
    run_tests(args.host, args.image)
