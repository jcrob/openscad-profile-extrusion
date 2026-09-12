// Top-down plan matching rim_piece_assembly:
// - Ingress: hollow U from the inner edge into the glass (no rim in the opening).
// - Cord hole: outer-Ø boss fused to the inner flange edge, inner bore open.

import { featHasIngress, ingressBay } from "./rimModel.js";

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

/** Hollow U: from inner edge into the glass. Opening = bay, depth = ingress_depth. */
export function ingressUDetour(arm, bay, depth) {
  const half = Math.min(bay, arm.length * 0.9) / 2;
  const [ix, iz] = alongInner(arm, 0.5);
  const ax = arm.axis === "x" ? (arm.dx >= 0 ? 1 : -1) : 0;
  const az = arm.axis === "z" ? (arm.dz >= 0 ? 1 : -1) : 0;
  const left = [ix - ax * half, iz - az * half];
  const right = [ix + ax * half, iz + az * half];
  const farL = [left[0] + arm.inX * depth, left[1] + arm.inZ * depth];
  const farR = [right[0] + arm.inX * depth, right[1] + arm.inZ * depth];
  return { left, farL, farR, right, depth, bay: half * 2 };
}

function detourOnInner(points, arm, u, eps = 0.8) {
  if (!u) return points;
  const out = [];
  for (let i = 0; i < points.length; i++) {
    const a = points[i];
    const b = points[(i + 1) % points.length];
    out.push(a);
    if (!isInnerEdge(a, b, arm, eps)) continue;
    const ta = tAlongInner(arm, a);
    const tb = tAlongInner(arm, b);
    const t0 = Math.min(ta, tb);
    const t1 = Math.max(ta, tb);
    if (t0 > 0.55 || t1 < 0.45) continue;
    const startToEnd = ta < tb;
    const seq = startToEnd
      ? [u.left, u.farL, u.farR, u.right]
      : [u.right, u.farR, u.farL, u.left];
    out.push(...seq);
  }
  return out;
}

function isInnerEdge(a, b, arm, eps) {
  const mid = [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2];
  if (arm.axis === "x") return Math.abs(mid[1] - arm.innerAt) < eps;
  return Math.abs(mid[0] - arm.innerAt) < eps;
}

function tAlongInner(arm, p) {
  const [ix, iz] = alongInner(arm, 0);
  const [jx, jz] = alongInner(arm, 1);
  const dx = jx - ix;
  const dz = jz - iz;
  const len2 = dx * dx + dz * dz || 1;
  return ((p[0] - ix) * dx + (p[1] - iz) * dz) / len2;
}

export function outlinePoints(piece) {
  let pts;
  if (piece.points) pts = piece.points.map((p) => [...p]);
  else {
    const { x, z, w, h } = piece;
    pts = [
      [x, z],
      [x + w, z],
      [x + w, z + h],
      [x, z + h],
    ];
  }
  const f = piece.feat || {};
  if (featHasIngress(f)) {
    const arm = pickArm(piece, f.ingress_on || "a");
    if (arm) {
      const u = ingressUDetour(arm, ingressBay(f.ingress_opening), Math.max(16, f.ingress_depth || 30));
      pts = detourOnInner(pts, arm, u);
    }
  }
  return pts;
}

export function featureShapes(piece) {
  const f = piece.feat || {};
  const shapes = [];
  if (featHasIngress(f)) {
    const arm = pickArm(piece, f.ingress_on || "a");
    if (arm) {
      const u = ingressUDetour(arm, ingressBay(f.ingress_opening), Math.max(16, f.ingress_depth || 30));
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
  const outline = lPath(outlinePoints(piece), ty);
  const holes = featureShapes(piece)
    .filter((s) => s.kind === "hole")
    .map((s) => circlePath(s.cx, s.cz, s.inner_r, ty));
  return [outline, ...holes].join(" ");
}

export function cordBossPath(piece, ty) {
  return featureShapes(piece)
    .filter((s) => s.kind === "hole")
    .map((s) => `${circlePath(s.cx, s.cz, s.outer_r, ty)} ${circlePath(s.cx, s.cz, s.inner_r, ty)}`)
    .join(" ");
}

export function ingressUPath() {
  return "";
}
