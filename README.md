# Aquarium Lid Parts → Bambu Print

Local LAN webapp: configure edge/corner aquarium-lid parts, generate STLs with OpenSCAD, arrange & slice with OrcaSlicer (fixed Bambu profiles), then send a `.gcode.3mf` to a Bambu printer over LAN — or download the file if the printer is offline.

## Features

- **Parts list UI** — add edge replicas (length, stem grippers, cord hole/under, lid ingress) and corner assemblies
- **BOM summary** — piece counts and plate-fill estimate (rejects oversized jobs when slicing)
- **OpenSCAD export** — uses `edgereplica.scad` / `cornerpiece.scad` (`show_edge_fit_preview` off for print)
- **OrcaSlicer** — locked machine / process / filament under `print-profiles/`
- **Bambu LAN** — FTPS upload + MQTT `project_file` (IP + access code + serial)
- **Fallback** — download `.gcode.3mf` (or STL zip if Orca is not installed)

## Requirements

| Tool | Role |
|------|------|
| Python 3.11+ | API (`server/`) |
| Node 20+ | Build UI (`web/`) |
| [OpenSCAD](https://openscad.org/) | STL generation |
| [OrcaSlicer](https://github.com/SoftFever/OrcaSlicer) CLI | Arrange + slice (optional but recommended) |
| Bambu P1S / X1C-class on LAN | Print (optional; download always works) |

## Quick start (dev)

```bash
# API deps
python3 -m venv .venv
source .venv/bin/activate
pip install -r server/requirements.txt

# UI
cd web && npm install && npm run build && cd ..

# Env for printer (optional)
cp .env.example .env
# edit BAMBU_IP, BAMBU_ACCESS_CODE, BAMBU_SERIAL

# Run
export OPENSCAD_BIN=openscad   # or path to AppImage AppRun
export ORCA_BIN=orca-slicer    # optional
python -m uvicorn server.main:app --host 0.0.0.0 --port 8080
```

Open **http://localhost:8080/**.

### API-only / Vite proxy

```bash
# terminal 1
uvicorn server.main:app --reload --port 8080

# terminal 2
cd web && npm run dev   # http://localhost:5173 → proxies /api
```

## Printer setup (LAN)

1. On the printer: enable **LAN Only** (or Developer) mode and note the **access code**.
2. Find the printer **IP** and **serial** (Bambu network / device info).
3. Put them in `.env`:

```env
BAMBU_IP=192.168.1.50
BAMBU_ACCESS_CODE=12345678
BAMBU_SERIAL=01P00A000000000
```

The API uploads the project over **FTPS** (`ftps://IP/printerIP/…`) then publishes MQTT `project_file` on `mqtts://IP:8883`.

## Orca profiles

Locked presets in `print-profiles/`:

- `machine.json` — Bambu P1S 0.4 nozzle, Textured PEI
- `process.json` — 0.20 mm, 3 walls, 20% gyroid
- `filament.json` — Generic PLA

Swap JSON files to change printer class; all jobs use the same profiles (no per-part overrides in v1).

Orca CLI (when installed):

```bash
orca-slicer --arrange 1 --orient 1 --allow-rotations \
  --load-settings "print-profiles/machine.json;print-profiles/process.json" \
  --load-filaments "print-profiles/filament.json" \
  --slice 0 --export-3mf out.gcode.3mf *.stl
```

If Orca is missing, the job still produces a **ZIP of STLs** for manual import.

## Docker

```bash
cd web && npm ci && npm run build && cd ..
cp .env.example .env   # fill printer vars

# Optional: put OrcaSlicer binary at ./orca-host/orca-slicer
docker compose up --build
```

On Linux, for reliable printer reachability, prefer host networking:

```yaml
# in docker-compose.yml
network_mode: host
```

Open **http://localhost:8080/**.

## Project layout

```
server/           FastAPI + OpenSCAD + Orca + Bambu client
web/              Vite + React UI
scad/             Symlinks to OpenSCAD sources
print-profiles/   Locked Bambu/Orca JSON
edgereplica.scad / cornerpiece.scad
```

## API

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Tools + BOM limits |
| GET | `/api/printer` | Configured? |
| POST | `/api/jobs` | Body: parts list JSON → job |
| GET | `/api/jobs/{id}` | Status |
| GET | `/api/jobs/{id}/download` | `.gcode.3mf` or STL zip |
| POST | `/api/jobs/{id}/print` | Send to Bambu |

Example body:

```json
{
  "name": "aquarium-lid-plate",
  "parts": [
    {
      "kind": "edge",
      "length": 300,
      "stem_gripper_sides": 2,
      "cord_hole": true,
      "cord_hole_inner_d": 8,
      "cord_hole_pos": "left",
      "cord_under": false,
      "cord_under_gap_len": 14,
      "lid_ingress": false,
      "ingress_depth": 40,
      "ingress_length": 60,
      "ingress_remove_right_rim": false,
      "qty": 1
    },
    { "kind": "corner", "qty": 4 }
  ]
}
```

## Out of scope (v1)

- Multi-printer farm / Hub API
- AMS multi-color mapping
- Public internet hosting
- Editing corner Customizer geometry in the UI (stock corners + qty only)
