"""Generate OpenSCAD wrappers and export STLs."""
from __future__ import annotations

import os
import shutil
import subprocess
import uuid
from pathlib import Path

from .config import settings
from .models import CornerPart, EdgePart, PartsList


def _openscad_cmd() -> list[str]:
    bin_path = settings.openscad_bin
    # Prefer AppImage extract if present in cloud agent env
    apprun = Path("/tmp/squashfs-root/AppRun")
    if bin_path == "openscad" and apprun.exists():
        return [str(apprun)]
    return [bin_path]


def openscad_available() -> bool:
    cmd = _openscad_cmd()
    if Path(cmd[0]).exists():
        return True
    return shutil.which(cmd[0]) is not None


def _scad_bool(v: bool) -> str:
    return "true" if v else "false"


def _scad_str(v: str) -> str:
    return f'"{v}"'


def write_edge_wrapper(path: Path, edge: EdgePart) -> None:
    path.write_text(
        f"""// Auto-generated edge part
include <edgereplica.scad>
edgereplica(
    length = {edge.length},
    stem_gripper_sides = {edge.stem_gripper_sides},
    cord_hole = {_scad_bool(edge.cord_hole)},
    cord_hole_inner_d = {edge.cord_hole_inner_d},
    cord_hole_pos = {_scad_str(edge.cord_hole_pos.value)},
    cord_under = {_scad_bool(edge.cord_under)},
    cord_under_gap_len = {edge.cord_under_gap_len},
    lid_ingress = {_scad_bool(edge.lid_ingress)},
    ingress_depth = {edge.ingress_depth},
    ingress_length = {edge.ingress_length},
    ingress_remove_right_rim = {_scad_bool(edge.ingress_remove_right_rim)}
);
""",
        encoding="utf-8",
    )


def run_openscad(
    scad_path: Path,
    stl_path: Path,
    defines: list[str] | None = None,
    timeout: int = 180,
) -> None:
    cmd = _openscad_cmd()
    for d in defines or []:
        cmd.extend(["-D", d])
    cmd.extend(["-o", str(stl_path), str(scad_path)])
    env = {**os.environ, "OPENSCADPATH": str(settings.scad_dir)}
    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=timeout,
        cwd=str(settings.scad_dir),
        env=env,
    )
    if proc.returncode != 0 or not stl_path.exists():
        raise RuntimeError(
            f"OpenSCAD failed ({proc.returncode}): {proc.stderr[-2000:] or proc.stdout[-2000:]}"
        )


def estimate_footprint_mm(part: EdgePart | CornerPart) -> tuple[float, float]:
    """Rough XY footprint for plate-fill warning (mm)."""
    if isinstance(part, EdgePart):
        w = 14.0 + (part.ingress_depth if part.lid_ingress else 0)
        d = part.length
        return (w, d)
    # Full corner assembly (both halves) ~ 55x35
    return (55.0, 35.0)


def build_bom(parts_list: PartsList) -> dict:
    edges = 0
    corners = 0
    stls = 0
    area = 0.0
    for p in parts_list.parts:
        if isinstance(p, EdgePart):
            edges += p.qty
            stls += p.qty
            w, d = estimate_footprint_mm(p)
            area += w * d * p.qty
        else:
            corners += p.qty
            stls += p.qty  # one STL per assembly (both halves)
            w, d = estimate_footprint_mm(p)
            area += w * d * p.qty
    bed = settings.bed_width_mm * settings.bed_depth_mm
    return {
        "edge_count": edges,
        "corner_assemblies": corners,
        "stl_count": stls,
        "approx_area_mm2": round(area, 1),
        "bed_area_mm2": bed,
        "plate_fill_ratio": round(area / bed, 3) if bed else 0,
        "plate_ok": area <= bed * 0.85,
    }


def generate_stls(parts_list: PartsList, job_dir: Path) -> list[Path]:
    stl_dir = job_dir / "stl"
    scad_out = job_dir / "scad"
    stl_dir.mkdir(parents=True, exist_ok=True)
    scad_out.mkdir(parents=True, exist_ok=True)

    stls: list[Path] = []
    idx = 0
    for part in parts_list.parts:
        if isinstance(part, EdgePart):
            for _q in range(part.qty):
                idx += 1
                scad = scad_out / f"edge_{idx}.scad"
                stl = stl_dir / f"edge_{idx}.stl"
                write_edge_wrapper(scad, part)
                run_openscad(scad, stl)
                stls.append(stl)
        else:
            for _q in range(part.qty):
                idx += 1
                stl = stl_dir / f"corner_{idx}.stl"
                # Print both halves as one assembly; disable translucent fit preview
                run_openscad(
                    settings.scad_dir / "cornerpiece.scad",
                    stl,
                    defines=["show_edge_fit_preview=false"],
                )
                stls.append(stl)
    return stls


def new_job_dir(name: str) -> tuple[str, Path]:
    job_id = f"{uuid.uuid4().hex[:10]}_{name.replace(' ', '_')[:24]}"
    job_dir = settings.jobs_dir / job_id
    if job_dir.exists():
        shutil.rmtree(job_dir)
    job_dir.mkdir(parents=True)
    return job_id, job_dir
