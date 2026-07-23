# Aquarium lid parts → Bambu print webapp
# Host must be on the same LAN as the printer for MQTT/FTPS send.
FROM python:3.12-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates xz-utils libgl1 libglu1-mesa libegl1 libx11-6 \
    libxext6 libxi6 libxrender1 libsm6 libice6 libdbus-1-3 libfontconfig1 \
    libfreetype6 xvfb \
    && rm -rf /var/lib/apt/lists/*

# OpenSCAD AppImage (headless via xvfb-run if needed)
ARG OPENSCAD_URL=https://files.openscad.org/OpenSCAD-2021.01-x86_64.AppImage
RUN curl -fsSL -o /opt/OpenSCAD.AppImage "$OPENSCAD_URL" \
    && chmod +x /opt/OpenSCAD.AppImage \
    && cd /opt && ./OpenSCAD.AppImage --appimage-extract \
    && ln -sf /opt/squashfs-root/AppRun /usr/local/bin/openscad \
    && rm -f /opt/OpenSCAD.AppImage

# OrcaSlicer is large; mount a host binary or install at runtime.
# Place orca-slicer on PATH or set ORCA_BIN. Without it, jobs export a ZIP of STLs.

WORKDIR /app
COPY server/requirements.txt /app/server/requirements.txt
RUN pip install --no-cache-dir -r /app/server/requirements.txt

COPY server /app/server
COPY edgereplica.scad cornerpiece.scad profile_extrusion.scad /app/
# Real files in scad/ (avoid broken symlinks in the image)
RUN mkdir -p /app/scad \
    && ln -sf /app/edgereplica.scad /app/scad/edgereplica.scad \
    && ln -sf /app/cornerpiece.scad /app/scad/cornerpiece.scad \
    && ln -sf /app/profile_extrusion.scad /app/scad/profile_extrusion.scad
COPY print-profiles /app/print-profiles
COPY web/dist /app/web/dist

ENV OPENSCAD_BIN=/usr/local/bin/openscad \
    SCAD_DIR=/app/scad \
    PROFILES_DIR=/app/print-profiles \
    JOBS_DIR=/data/jobs \
    HOST=0.0.0.0 \
    PORT=8080 \
    PYTHONUNBUFFERED=1

RUN mkdir -p /data/jobs
EXPOSE 8080
VOLUME ["/data/jobs"]

CMD ["python", "-m", "uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8080"]
