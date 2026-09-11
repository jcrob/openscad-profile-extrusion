// Top-down SVG: piece fill with real cutouts (ingress U-break, cord hole).

import { featHasIngress, ingressBay } from "./rimModel.js";

/** Outer back of the U — leftover rim after ingress breaks the inner edge. */
export const INGRESS_BACK_WALL = 6;
const INNER_OVERLAP = 2.4;

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
    if (p.points) {
      for (const [x, z] of p.points) grow(x, z);
    } else {
      grow(p.x, p.z);
      grow(p.x + p.w, p.z + p.h);
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

export function rectPath(x, z, w, h, ty) {
  const y = ty(z + h);
  return `M ${x} ${y} H ${x + w} V ${y + h} H ${x} Z`;
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

function alongPoint(arm, t) {
  return [arm.mx + arm.dx * t, arm.mz + arm.dz * t];
}

/** Notch from the inner (glass) edge. overlap > 0 opens the outline (rim breaks). */
function innerNotch(arm, width, depth, t, overlap) {
  const half = Math.min(width, arm.length * 0.9) / 2;
  const cut = Math.min(depth, arm.thick - 1);
  const [cx, cz] = alongPoint(arm, t);
  if (arm.axis === "x") {
    if (arm.inZ > 0) {
      return { x: cx - half, z: arm.innerAt - cut + overlap, w: half * 2, h: cut };
    }
    return { x: cx - half, z: arm.innerAt - overlap, w: half * 2, h: cut };
  }
  if (arm.inX > 0) {
    return { x: arm.innerAt - cut + overlap, z: cz - half, w: cut, h: half * 2 };
  }
  return { x: arm.innerAt - overlap, z: cz - half, w: cut, h: half * 2 };
}

function pickArm(piece, on) {
  if (piece.kind === "corner") return piece.arms?.[on] || piece.arms?.a;
  return piece.arms?.a;
}

export function featureShapes(piece) {
  const f = piece.feat || {};
  const shapes = [];

  if (featHasIngress(f)) {
    const arm = pickArm(piece, f.ingress_on || "a");
    if (arm) {
      const bay = ingressBay(f.ingress_opening);
      const depth = Math.max(
        arm.thick - INGRESS_BACK_WALL,
        Math.min(arm.thick * 0.82, f.ingress_depth || arm.thick)
      );
      shapes.push({
        kind: "ingress",
        ...innerNotch(arm, bay, depth, 0.5, INNER_OVERLAP),
        opens: true,
      });
    }
  }
  if (f.cord_under) {
    const arm = pickArm(piece, f.cord_under_on || "a");
    if (arm) {
      const gap = Math.max(6, f.cord_under_gap_len || 20);
      shapes.push({
        kind: "under",
        ...innerNotch(arm, gap, arm.thick * 0.4, 0.5, INNER_OVERLAP),
        opens: true,
      });
    }
  }
  if (f.cord_hole) {
    const arm = pickArm(piece, f.cord_hole_on || "a");
    if (arm) {
      const [cx, cz] = alongPoint(arm, posT(f.cord_hole_pos));
      const r = Math.max(2.2, (f.cord_hole_inner_d || 6) / 2);
      const maxR = arm.thick / 2 - 1.2;
      shapes.push({ kind: "hole", cx, cz, r: Math.min(r, maxR) });
    }
  }
  return shapes;
}

/** Even-odd fill path: outline minus ingress U-break and cord hole. */
export function piecePath(piece, ty) {
  const outline = piece.points
    ? lPath(piece.points, ty)
    : rectPath(piece.x, piece.z, piece.w, piece.h, ty);
  const cuts = featureShapes(piece).map((s) => {
    if (s.kind === "hole") return circlePath(s.cx, s.cz, s.r, ty);
    return rectPath(s.x, s.z, s.w, s.h, ty);
  });
  return [outline, ...cuts].join(" ");
}
