#!/usr/bin/env python3
"""Assert NW-fixed blowout: far axes are gap*(n+1), sides copy start corners.

Mirrors rim_rectangular_lid.scad planning + offset functions.
"""
from __future__ import annotations

import math
import sys

EDGE_LEFT_FLANGE_T = 2.8
EDGE_LEFT_FLAT_W = 3.4
EDGE_TOP_THICKNESS = 6.0
EDGE_STEM_ROOT_W = EDGE_TOP_THICKNESS
EDGE_RIGHT_SEGMENT_ROOT_T = EDGE_TOP_THICKNESS
GLASS_THICKNESS = 11.0
EDGE_STEM_ROOT_RIGHT = EDGE_LEFT_FLANGE_T + EDGE_LEFT_FLAT_W + EDGE_STEM_ROOT_W
EDGE_PROFILE_MAX_X = EDGE_STEM_ROOT_RIGHT + EDGE_RIGHT_SEGMENT_ROOT_T + GLASS_THICKNESS

RIM_MAX_PIECE_LEN = 200.0
RIM_CORNER_SPLIT = 400.0
RIM_LAYOUT_GAP = 12.0


def corner_leg_for_dim(dim, max_len=RIM_MAX_PIECE_LEN, split=RIM_CORNER_SPLIT):
    return dim / 2 if dim <= split else max_len


def auto_corner_leg(gw, gd, max_len=RIM_MAX_PIECE_LEN, split=RIM_CORNER_SPLIT):
    return max(
        EDGE_PROFILE_MAX_X + 1,
        min(corner_leg_for_dim(gw, max_len, split), corner_leg_for_dim(gd, max_len, split)),
    )


def side_straight_total(glass_dim, leg):
    return max(0.0, glass_dim - 2 * leg)


def straight_segments(run_len, max_len=RIM_MAX_PIECE_LEN):
    if run_len <= 0:
        return []
    n_full = math.floor(run_len / max_len)
    partial = run_len - n_full * max_len
    if n_full == 0:
        return [run_len]
    segs = [max_len] * n_full
    if partial > 0:
        segs.append(partial)
    return segs


def side_seg_count(side_idx, gw, gd):
    leg = auto_corner_leg(gw, gd)
    dim = gw if side_idx in (0, 2) else gd
    return len(straight_segments(side_straight_total(dim, leg)))


def blowout_gap_size(layout_gap=RIM_LAYOUT_GAP * 2, blowout_gap=0.0):
    return blowout_gap if blowout_gap > 0 else layout_gap + EDGE_PROFILE_MAX_X


def axis_gaps(gw, gd, gap):
    gx = gap * (side_seg_count(0, gw, gd) + 1)
    gz = gap * (side_seg_count(1, gw, gd) + 1)
    return gx, gz


def corner_offset(ci, gap, gw, gd):
    gx, gz = axis_gaps(gw, gd, gap)
    if ci == 0:
        return (-gap, 0.0, -gz)
    if ci == 1:
        return (gx, 0.0, -gz)
    if ci == 2:
        return (gx, 0.0, gap)
    return (-gap, 0.0, gap)


def side_offset(si, gap, gw, gd):
    gx, gz = axis_gaps(gw, gd, gap)
    if si == 0:
        return (-gap, 0.0, -gz)
    if si == 1:
        return (gx, 0.0, -gz)
    if si == 2:
        return (gx, 0.0, gap)
    return (-gap, 0.0, gap)


def assert_close(a, b, msg, tol=1e-9):
    if abs(a - b) > tol:
        raise AssertionError(f"{msg}: {a} != {b}")


def check_case(gw, gd, label):
    gap = blowout_gap_size()
    ns, ne_n, nn, nw_n = (side_seg_count(i, gw, gd) for i in range(4))
    gx, gz = axis_gaps(gw, gd, gap)
    sw, se, ne, nw = (corner_offset(i, gap, gw, gd) for i in range(4))
    south, east, north, west = (side_offset(i, gap, gw, gd) for i in range(4))

    # NW is fixed at (-gap, +gap).
    assert_close(nw[0], -gap, f"{label} NW X = -gap")
    assert_close(nw[2], gap, f"{label} NW Z = +gap")

    # Far axes: gx from south (X-run) segs, gz from east (Z-run) segs.
    assert_close(gx, gap * (ns + 1), f"{label} gx = gap*(nx+1)")
    assert_close(gz, gap * (ne_n + 1), f"{label} gz = gap*(nz+1)")
    assert_close(se[0], gx, f"{label} SE X = gx")
    assert_close(sw[2], -gz, f"{label} SW Z = -gz")

    # Sides copy clockwise-start corners.
    assert_close(south[0], sw[0], f"{label} south X vs SW")
    assert_close(south[2], sw[2], f"{label} south Z vs SW")
    assert_close(east[0], se[0], f"{label} east X vs SE")
    assert_close(east[2], se[2], f"{label} east Z vs SE")
    assert_close(north[0], ne[0], f"{label} north X vs NE")
    assert_close(north[2], ne[2], f"{label} north Z vs NE")
    assert_close(west[0], nw[0], f"{label} west X vs NW")
    assert_close(west[2], nw[2], f"{label} west Z vs NW")

    # Shared row/column.
    assert_close(sw[2], se[2], f"{label} south-row Z")
    assert_close(se[0], ne[0], f"{label} east-column X")
    assert_close(nw[0], sw[0], f"{label} west-column X")
    assert_close(nw[2], ne[2], f"{label} north-row Z")

    print(
        f"ok  {label}: glass {gw:.0f}×{gd:.0f}  gap={gap:.2f}  "
        f"segs X/Z={ns}/{ne_n}  gx/gz={gx:.1f}/{gz:.1f}  "
        f"NW={nw} SE={se}"
    )


def main():
    print(f"edge_profile_max_x = {EDGE_PROFILE_MAX_X:.2f} mm")
    check_case(600, 450, "default-lid")
    check_case(900, 600, "demo-lid")
    check_case(350, 300, "small-half-legs")
    check_case(800, 800, "square-multi-seg")
    print("all NW-fixed blowout offset checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
