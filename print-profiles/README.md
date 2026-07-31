# Print profiles (locked)

These JSON files are loaded by OrcaSlicer CLI for every plate job.

| File | Role |
|------|------|
| `machine.json` | Bambu Lab P1S 0.4 mm nozzle, 256×256 bed |
| `process.json` | 0.20 mm layer, 3 walls, 25% grid infill |
| `filament.json` | Generic PLA |

## Replacing with studio-exported profiles

For best results, export real profiles from OrcaSlicer / Bambu Studio:

1. Open OrcaSlicer → select your printer, process, and filament.
2. Export each as JSON (or copy from Orca user `system` / `user` presets folder).
3. Overwrite the three files here, keeping the same filenames.
4. Restart the API.

All jobs share these profiles — no per-part overrides in v1.
