"""Aquarium lid parts → Bambu print API."""
from __future__ import annotations

import json
import traceback
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from .bambu_client import get_printer_status, send_to_printer
from .config import ROOT, settings
from .models import JobStatus, PartsList, PrintRequest
from .scad_export import build_bom, generate_stls, new_job_dir, openscad_available
from .slicer import orca_available, slice_and_arrange, zip_stls

app = FastAPI(title="Aquarium Lid Bambu Print", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_jobs: dict[str, dict] = {}


@app.get("/api/health")
def health():
    oscad = openscad_available()
    return {
        "ok": oscad,
        "openscad": oscad,
        "orca": orca_available(),
        "printer_configured": get_printer_status().configured,
    }


@app.get("/api/printer")
def printer():
    return get_printer_status()


@app.post("/api/jobs", response_model=JobStatus)
def create_job(parts_list: PartsList):
    bom = build_bom(parts_list)
    if not bom["plate_ok"]:
        # Still allow generation but flag it
        pass

    job_id, job_dir = new_job_dir(parts_list.name)
    meta = {
        "job_id": job_id,
        "status": "generating",
        "message": "Generating STLs with OpenSCAD…",
        "parts": parts_list.model_dump(),
        "bom": bom,
        "dir": str(job_dir),
    }
    _jobs[job_id] = meta
    (job_dir / "parts.json").write_text(parts_list.model_dump_json(indent=2), encoding="utf-8")

    try:
        stls = generate_stls(parts_list, job_dir)
        meta["stl_count"] = len(stls)
        meta["stls"] = [str(s) for s in stls]
        meta["status"] = "slicing"
        meta["message"] = "Arranging and slicing with OrcaSlicer…"

        out_3mf = job_dir / f"{parts_list.name}.gcode.3mf"
        if orca_available():
            if not bom["plate_ok"]:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        f"Parts likely overflow one plate "
                        f"(fill≈{bom['plate_fill_ratio']:.0%}). Reduce qty and retry."
                    ),
                )
            slice_and_arrange(stls, out_3mf)
            meta["gcode_3mf"] = str(out_3mf)
            meta["status"] = "ready"
            meta["message"] = "Plate ready. Download or send to printer."
            meta["download_url"] = f"/api/jobs/{job_id}/download"
        else:
            zip_path = job_dir / f"{parts_list.name}-stls.zip"
            zip_stls(stls, zip_path)
            meta["gcode_3mf"] = None
            meta["stl_zip"] = str(zip_path)
            meta["status"] = "stls_only"
            meta["message"] = (
                "STLs generated. OrcaSlicer not installed — download STL zip, "
                "or install OrcaSlicer for auto arrange/slice/send."
            )
            meta["download_url"] = f"/api/jobs/{job_id}/download"
        (job_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    except HTTPException:
        raise
    except Exception as exc:
        meta["status"] = "error"
        meta["message"] = str(exc)
        (job_dir / "error.txt").write_text(traceback.format_exc(), encoding="utf-8")
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return JobStatus(
        job_id=job_id,
        status=meta["status"],
        message=meta["message"],
        stl_count=meta.get("stl_count", 0),
        gcode_3mf=Path(meta["gcode_3mf"]).name if meta.get("gcode_3mf") else None,
        download_url=meta.get("download_url"),
        plate_ok=bom["plate_ok"],
        bom=bom,
    )


@app.get("/api/jobs/{job_id}", response_model=JobStatus)
def get_job(job_id: str):
    meta = _jobs.get(job_id)
    if not meta:
        meta_path = settings.jobs_dir / job_id / "meta.json"
        if meta_path.exists():
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
            _jobs[job_id] = meta
        else:
            raise HTTPException(status_code=404, detail="job not found")
    return JobStatus(
        job_id=job_id,
        status=meta["status"],
        message=meta.get("message", ""),
        stl_count=meta.get("stl_count", 0),
        gcode_3mf=Path(meta["gcode_3mf"]).name if meta.get("gcode_3mf") else None,
        download_url=meta.get("download_url"),
        plate_ok=meta.get("bom", {}).get("plate_ok", True),
        bom=meta.get("bom", {}),
    )


@app.get("/api/jobs/{job_id}/download")
def download_job(job_id: str):
    meta = _jobs.get(job_id)
    if not meta:
        meta_path = settings.jobs_dir / job_id / "meta.json"
        if not meta_path.exists():
            raise HTTPException(status_code=404, detail="job not found")
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
    path = meta.get("gcode_3mf") or meta.get("stl_zip")
    if not path or not Path(path).exists():
        raise HTTPException(status_code=404, detail="artifact not ready")
    return FileResponse(
        path,
        filename=Path(path).name,
        media_type="application/octet-stream",
    )


@app.post("/api/jobs/{job_id}/print")
def print_job(job_id: str, body: PrintRequest | None = None):
    meta = _jobs.get(job_id)
    if not meta:
        meta_path = settings.jobs_dir / job_id / "meta.json"
        if not meta_path.exists():
            raise HTTPException(status_code=404, detail="job not found")
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        _jobs[job_id] = meta

    gcode = meta.get("gcode_3mf")
    if not gcode or not Path(gcode).exists():
        raise HTTPException(
            status_code=400,
            detail="No .gcode.3mf for this job. Install OrcaSlicer and regenerate.",
        )
    try:
        msg = send_to_printer(
            Path(gcode),
            ip=body.bambu_ip if body else None,
            access_code=body.bambu_access_code if body else None,
            serial=body.bambu_serial if body else None,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    meta["status"] = "sent"
    meta["message"] = msg
    return {"ok": True, "message": msg}


# Serve built UI if present (always under repo ROOT/web/dist)
_web_dist = ROOT / "web" / "dist"
if _web_dist.exists():
    app.mount("/", StaticFiles(directory=str(_web_dist), html=True), name="ui")
