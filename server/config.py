"""Environment configuration for the print webapp."""
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    scad_dir: Path = ROOT / "scad"
    jobs_dir: Path = ROOT / "jobs"
    profiles_dir: Path = ROOT / "print-profiles"

    openscad_bin: str = "openscad"
    orca_bin: str = "orca-slicer"

    # Locked print profile filenames (relative to profiles_dir)
    machine_profile: str = "machine.json"
    process_profile: str = "process.json"
    filament_profile: str = "filament.json"

    # Bambu LAN printer
    bambu_ip: str = ""
    bambu_access_code: str = ""
    bambu_serial: str = ""
    bambu_mqtt_port: int = 8883

    # Approximate printable area for BOM warnings (P1S / X1C, mm)
    bed_width_mm: float = 256.0
    bed_depth_mm: float = 256.0


settings = Settings()
settings.jobs_dir.mkdir(parents=True, exist_ok=True)