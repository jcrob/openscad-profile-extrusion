"""OrcaSlicer CLI arrange + slice to Bambu .gcode.3mf."""
from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from .config import settings


def orca_available() -> bool:
    return shutil.which(settings.orca_bin) is not None


def profile_paths() -> tuple[Path, Path, Path]:
    d = settings.profiles_dir
    machine = d / settings.machine_profile
    process = d / settings.process_profile
    filament = d / settings.filament_profile
    for p in (machine, process, filament):
        if not p.exists():
            raise FileNotFoundError(f"Missing print profile: {p}")
    return machine, process, filament


def slice_and_arrange(stls: list[Path], out_3mf: Path) -> Path:
    """Arrange STLs on plate and export Bambu-compatible .gcode.3mf."""
    if not stls:
        raise ValueError("no STLs to slice")
    if not orca_available():
        raise RuntimeError(
            f"OrcaSlicer not found (`{settings.orca_bin}`). "
            "Install OrcaSlicer and ensure it is on PATH, or set ORCA_BIN."
        )

    machine, process, filament = profile_paths()
    out_3mf.parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        settings.orca_bin,
        "--arrange",
        "1",
        "--orient",
        "1",
        "--allow-rotations",
        "--load-settings",
        f"{machine};{process}",
        "--load-filaments",
        str(filament),
        "--slice",
        "0",
        "--export-3mf",
        str(out_3mf),
        *[str(s) for s in stls],
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if proc.returncode != 0 or not out_3mf.exists():
        raise RuntimeError(
            "OrcaSlicer failed:\n"
            + (proc.stderr[-3000:] or proc.stdout[-3000:] or "(no output)")
        )
    return out_3mf


def zip_stls(stls: list[Path], zip_path: Path) -> Path:
    """Fallback artifact when slicer is unavailable."""
    import zipfile

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for s in stls:
            zf.write(s, arcname=s.name)
    return zip_path
