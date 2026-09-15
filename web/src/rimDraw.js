// Top-down plan matching rim_piece_assembly:
// - Ingress: rim U-walls around the inner cut; cavity is wrap background.
// - Cord hole: outer-Ø boss fused to the inner flange edge, inner bore open.

import { featHasIngress } from "./rimModel.js";

const CORD_FUSE = 2;

export function worldBounds(pieces, gw, gd, pad = 40) {
  let minX = 0;
  let minZ = 0;
  let maxX = gw;
  let maxZ = gd;
  const grow = (x, z) => {
    if (x < minX) minX = x;
    if (z < minZ) minZ = z;
    if (x > maxX) maxX = x;
    if (z > maxZ) maxZ = z;
  };
  for (const p of pieces) {
    for (const [x, z] of outlinePoints(p)) grow(x, z);
    for (const s of featureShapes(p)) {
      if (s.kind === "hole") {
        grow(s.cx - s.outer_r, s.cz - s.outer_r);
        grow(s.cx + s.outer_r, s.cz + s.outer_r);
      }
      if (s.kind === "ingress") {
        for (const pt of [s.outer.left, s.outer.farL, s.outer.farR, s.outer.right]) {
          grow(pt[0], pt[1]);
        }
      }
    }
  }
  minX -= pad;
  minZ -= pad;
  maxX += pad;
  maxZ += pad;
  const vbW = maxX - minX;
  const vbH = maxZ - minZ;
  const ty = (z) => maxZ - z;
  return {
    minX,
    minZ,
    maxX,
    maxZ,
    vbW,
    vbH,
    ty,
    viewBox: `${minX} 0 ${vbW} ${vbH}`,
  };
}

export function lPath(points, ty) {
  return (
    points
      .map(([x, z], i) => `${i === 0 ? "M" : "L"} ${x} ${ty(z)}`)
      .join(" ") + " Z"
  );
}

export function circlePath(cx, cz, r, ty) {
  const cy = ty(cz);
  return `M ${cx - r} ${cy} a ${r} ${r} 0 1 0 ${2 * r} 0 a ${r} ${r} 0 1 0 ${-2 * r} 0 Z`;
}

function posT(pos) {
  if (pos === "left") return 1 / 3;
  if (pos === "right") return 2 / 3;
  return 0.5;
}

function alongCenter(arm, t) {
  return [arm.mx + arm.dx * t, arm.mz + arm.dz * t];
}

export function alongInner(arm, t) {
  const [cx, cz] = alongCenter(arm, t);
  const half = arm.thick / 2;
  return [cx + arm.inX * half, cz + arm.inZ * half];
}

function pickArm(piece, on) {
  if (piece.kind === "corner") return piece.arms?.[on] || piece.arms?.a;
  return piece.arms?.a;
}

export function cordOuterR(inner_d) {
  return (inner_d + inner_d / 3) / 2;
}

/** Outer Ø sits on the inner flange tip (3D: x0 = fuse - outer_r). */
export function cordHoleCenter(arm, t, inner_d) {
  const [ix, iz] = alongInner(arm, t);
  const outer_r = cordOuterR(inner_d);
  const shift = outer_r - CORD_FUSE;
  return {
    cx: ix + arm.inX * shift,
    cz: iz + arm.inZ * shift,
    inner_r: inner_d / 2,
    outer_r,
  };
}

function armAlong(arm) {
  return {
    ax: arm.axis === "x" ? (arm.dx >= 0 ? 1 : -1) : 0,
    az: arm.axis === "z" ? (arm.dz >= 0 ? 1 : -1) : 0,
  };
}

function uCorners(arm, half, depth) {
  const [ix, iz] = alongInner(arm, 0.5);
  const { ax, az } = armAlong(arm);
  const left = [ix - ax * half, iz - az * half];
  const right = [ix + ax * half, iz + az * half];
  return {
    left,
    farL: [left[0] + arm.inX * depth, left[1] + arm.inZ * depth],
    farR: [right[0] + arm.inX * depth, right[1] + arm.inZ * depth],
    right,
    depth,
    span: half * 2,
  };
}

/**
 * Hollow U from the inner flange into the glass.
 * Inner quad = clear opening × depth (cavity).
 * Outer quad = opening + 2×profile, depth + profile (rim walls on the inner cut).
 */
export function ingressGeometry(arm, opening, depth) {
  const wall = arm.thick;
  const innerHalf = Math.min(Math.max(opening, 2), arm.length * 0.9) / 2;
  const outerHalf = Math.min(innerHalf + wall, arm.length * 0.49);
  const innerDepth = Math.max(depth, 8);
  const outerDepth = innerDepth + wall;
  return {
    wall,
    opening: innerHalf * 2,
    bay: outerHalf * 2,
    inner: uCorners(arm, innerHalf, innerDepth),
    outer: uCorners(arm, outerHalf, outerDepth),
  };
}

export function ingressUDetour(arm, bay, depth) {
  return uCorners(arm, Math.min(bay, arm.length * 0.9) / 2, depth);
}

export function outlinePoints(piece) {
  if (piece.points) return piece.points.map((p) => [...p]);
  const { x, z, w, h } = piece;
  return [
    [x, z],
    [x + w, z],
    [x + w, z + h],
    [x, z + h],
  ];
}

export function featureShapes(piece) {
  const f = piece.feat || {};
  const shapes = [];
  if (featHasIngress(f)) {
    const arm = pickArm(piece, f.ingress_on || "a");
    if (arm) {
      const u = ingressGeometry(
        arm,
        f.ingress_opening,
        Math.max(16, f.ingress_depth || 30)
      );
      shapes.push({ kind: "ingress", ...u, opens: true, hollow: true });
    }
  }
  if (f.cord_hole) {
    const arm = pickArm(piece, f.cord_hole_on || "a");
    if (arm) {
      const inner_d = f.cord_hole_inner_d || 6;
      shapes.push({ kind: "hole", ...cordHoleCenter(arm, posT(f.cord_hole_pos), inner_d) });
    }
  }
  if (f.cord_under) {
    const arm = pickArm(piece, f.cord_under_on || "a");
    if (arm) {
      shapes.push({ kind: "under", gap: f.cord_under_gap_len || 20, arm });
    }
  }
  return shapes;
}

export function piecePath(piece, ty) {
  return lPath(outlinePoints(piece), ty);
}

/** Solid outer disc; inner Ø is the background overlay, not an even-odd stroke. */
export function cordBossPath(piece, ty) {
  return featureShapes(piece)
    .filter((s) => s.kind === "hole")
    .map((s) => circlePath(s.cx, s.cz, s.outer_r, ty))
    .join(" ");
}

/** Closed U ribbon: outer three sides then back along the inner cut. */
export function ingressWallPoints(s) {
  const o = s.outer;
  const i = s.inner;
  return [o.left, o.farL, o.farR, o.right, i.right, i.farR, i.farL, i.left];
}

/** Filled U walls (nonzero winding — not even-odd hole pairs). */
export function ingressWallPath(piece, ty) {
  return featureShapes(piece)
    .filter((s) => s.kind === "ingress")
    .map((s) => lPath(ingressWallPoints(s), ty))
    .join(" ");
}

export function openingFills(piece) {
  const out = [];
  for (const s of featureShapes(piece)) {
    if (s.kind === "hole") {
      out.push({ kind: "circle", cx: s.cx, cz: s.cz, r: s.inner_r });
    }
    if (s.kind === "ingress") {
      const arm = pickArm(piece, piece.feat?.ingress_on || "a");
      if (arm) out.push({ kind: "rect", ...rimBaySlot(arm, s.opening) });
      out.push({
        kind: "poly",
        points: [s.inner.left, s.inner.farL, s.inner.farR, s.inner.right],
      });
    }
  }
  return out;
}

/** Slot through the bar at the clear opening only — U walls stay on either side. */
export function rimBaySlot(arm, opening) {
  const half = Math.min(opening, arm.length * 0.9) / 2;
  const [cx, cz] = alongCenter(arm, 0.5);
  const pad = 0.6;
  if (arm.axis === "x") {
    return {
      x: cx - half,
      z: Math.min(arm.z, arm.innerAt) - pad,
      w: half * 2,
      h: arm.thick + 2 * pad,
    };
  }
  return {
    x: Math.min(arm.x, arm.innerAt) - pad,
    z: cz - half,
    w: arm.thick + 2 * pad,
    h: half * 2,
  };
}
