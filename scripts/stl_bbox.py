#!/usr/bin/env python3
"""Measure STL axis-aligned bounding box (ASCII or binary)."""
import re
import struct
import sys

def stl_bbox(path):
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:5] == b"solid":
        verts = re.findall(
            rb"vertex\s+([-+eE0-9.]+)\s+([-+eE0-9.]+)\s+([-+eE0-9.]+)",
            raw,
        )
        pts = [(float(x), float(y), float(z)) for x, y, z in verts]
    else:
        pts = []
        tri_count = struct.unpack("<I", raw[80:84])[0]
        off = 84
        for _ in range(tri_count):
            off += 12
            for _ in range(3):
                x, y, z = struct.unpack("<fff", raw[off:off + 12])
                pts.append((x, y, z))
                off += 12
            off += 2
    if not pts:
        raise ValueError("no vertices found")
    mins = [min(p[i] for p in pts) for i in range(3)]
    maxs = [max(p[i] for p in pts) for i in range(3)]
    return mins, maxs

if __name__ == "__main__":
    path = sys.argv[1]
    mins, maxs = stl_bbox(path)
    print(f"bbox min: {[round(v, 2) for v in mins]}")
    print(f"bbox max: {[round(v, 2) for v in maxs]}")
    print(f"size:   {[round(maxs[i] - mins[i], 2) for i in range(3)]}")
