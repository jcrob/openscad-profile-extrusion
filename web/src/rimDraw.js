// Top-down SVG matching 3D rim_piece_assembly features.
// Cord hole: outer boss at the flange tip (inner edge), inner bore punched.
// Ingress: full-width bay (no leftover rim) + U arms/back into the glass.

import { featHasIngress, ingressBay } from "./rimModel.js";

const CORD_FUSE = 2;
const EDGE_OVERLAP = 2.5;

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
  const growBox = (x, z, w, h) => {
    grow(x, z);
    grow(x + w, z + h);
  };
  for (const p of pieces) {
    if (p.points) {
      for (const [x, z] of p.points) grow(x, z);
    } else {
      growBox(p.x, p.z, p.w, p.h);
    }
    for (const s of featureShapes(p)) {
      if (s.kind === "hole") {
        grow(s.cx - s.outer_r, s.cz - s.outer_r);
        grow(s.cx + s.outer_r, s.cz + s.outer_r);
      } else if (s.x != null) {
        growBox(s.x, s.z, s.w, s.h);
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

function alongCenter(arm, t) {
  return [arm.mx + arm.dx * t, arm.mz + arm.dz * t];
}

/** Point on the inner (glass-facing) edge at parameter t. */
export function alongInner(arm, t) {
  const [cx, cz] = alongCenter(arm, t);
  const half = arm.thick / 2;
  return [cx + arm.inX * half, cz + arm.inZ * half];
}

function pickArm(piece, on) {
  if (piece.kind === "corner") return piece.arms?.[on] || piece.arms?.a;
  return piece.arms?.a;
}

export function cordOuterD(inner_d) {
  return inner_d + inner_d / 3;
}

export function cordOuterR(inner_d) {
  return cordOuterD(inner_d) / 2;
}

/** 3D: center at flange_tip + fuse - outer_r, so the outer Ø meets the inner edge. */
export function cordHoleCenter(arm, t, inner_d) {
  const [ix, iz] = alongInner(arm, t);
  const outer_r = cordOuterR(inner_d);
  const shift = outer_r - CORD_FUSE; // toward glass from the inner edge
  return {
    cx: ix + arm.inX * shift,
    cz: iz + arm.inZ * shift,
    inner_r: inner_d / 2,
    outer_r,
  };
}

/** Full-width bay: cut through the whole profile so no rim remains in the opening. */
function fullWidthBay(arm, width, t) {
  const half = Math.min(width, arm.length * 0.92) / 2;
  const [cx, cz] = alongCenter(arm, t);
  const cut = arm.thick + 2 * EDGE_OVERLAP;
  if (arm.axis === "x") {
    const z0 = Math.min(arm.z, arm.innerAt) - EDGE_OVERLAP;
    return { x: cx - half, z: z0, w: half * 2, h: cut };
  }
  const x0 = Math.min(arm.x, arm.innerAt) - EDGE_OVERLAP;
  return { x: x0, z: cz - half, w: cut, h: half * 2 };
}

function ingressUBoxes(arm, bay, depth) {
  const wall = arm.thick;
  const half = Math.min(bay, arm.length * 0.92) / 2;
  const [ix, iz] = alongInner(arm, 0.5);
  const inX = arm.inX;
  const inZ = arm.inZ;
  const alongX = arm.axis === "x" ? (arm.dx >= 0 ? 1 : -1) : 0;
  const alongZ = arm.axis === "z" ? (arm.dz >= 0 ? 1 : -1) : 0;
  // Left/right in the along direction from the bay center on the inner edge.
  const leftX = ix - alongX * half;
  const leftZ = iz - alongZ * half;
  const boxes = [];
  // Two arms into the glass, each one profile wide, length = ingress depth.
  if (arm.axis === "x") {
    const xL = Math.min(leftX, leftX + alongX * wall);
    const xR = Math.min(leftX + alongX * (2 * half - wall), leftX + alongX * 2 * half);
    const z0 = Math.min(iz, iz + inZ * depth);
    boxes.push({ kind: "ingress-arm", x: xL, z: z0, w: wall, h: Math.abs(inZ * depth) || depth });
    boxes.push({ kind: "ingress-arm", x: xR, z: z0, w: wall, h: Math.abs(inZ * depth) || depth });
    const zb = Math.min(iz + inZ * (depth - wall), iz + inZ * depth);
    boxes.push({ kind: "ingress-back", x: Math.min(leftX, leftX + alongX * 2 * half), z: zb, w: 2 * half, h: wall });
  } else {
    const zL = Math.min(leftZ, leftZ + alongZ * wall);
    const zR = Math.min(leftZ + alongZ * (2 * half - wall), leftZ + alongZ * 2 * half);
    const x0 = Math.min(ix, ix + inX * depth);
    boxes.push({ kind: "ingress-arm", x: x0, z: zL, w: Math.abs(inX * depth) || depth, h: wall });
    boxes.push({ kind: "ingress-arm", x: x0, z: zR, w: Math.abs(inX * depth) || depth, h: wall });
    const xb = Math.min(ix + inX * (depth - wall), ix + inX * depth);
    boxes.push({ kind: "ingress-back", x: xb, z: Math.min(leftZ, leftZ + alongZ * 2 * half), w: wall, h: 2 * half });
  }
  return boxes;
}

function innerNotch(arm, width, depth, t, overlap) {
  const half = Math.min(width, arm.length * 0.9) / 2;
  const cut = Math.min(depth, arm.thick - 1);
  const [cx, cz] = alongCenter(arm, t);
  if (arm.axis === "x") {
    if (arm.inZ > 0) return { x: cx - half, z: arm.innerAt - cut + overlap, w: half * 2, h: cut };
    return { x: cx - half, z: arm.innerAt - overlap, w: half * 2, h: cut };
  }
  if (arm.inX > 0) return { x: arm.innerAt - cut + overlap, z: cz - half, w: cut, h: half * 2 };
  return { x: arm.innerAt - overlap, z: cz - half, w: cut, h: half * 2 };
}

export function featureShapes(piece) {
  const f = piece.feat || {};
  const shapes = [];

  if (featHasIngress(f)) {
    const arm = pickArm(piece, f.ingress_on || "a");
    if (arm) {
      const bay = ingressBay(f.ingress_opening);
      const depth = Math.max(12, f.ingress_depth || 30);
      const bayBox = fullWidthBay(arm, bay, 0.5);
      shapes.push({ kind: "ingress", ...bayBox, opens: true, fullWidth: true });
      shapes.push(...ingressUBoxes(arm, bay, depth));
    }
  }
  if (f.cord_under) {
    const arm = pickArm(piece, f.cord_under_on || "a");
    if (arm) {
      const gap = Math.max(6, f.cord_under_gap_len || 20);
      shapes.push({
        kind: "under",
        ...innerNotch(arm, gap, arm.thick * 0.35, 0.5, EDGE_OVERLAP),
        opens: true,
      });
    }
  }
  if (f.cord_hole) {
    const arm = pickArm(piece, f.cord_hole_on || "a");
    if (arm) {
      const inner_d = f.cord_hole_inner_d || 6;
      shapes.push({
        kind: "hole",
        ...cordHoleCenter(arm, posT(f.cord_hole_pos), inner_d),
      });
    }
  }
  return shapes;
}

/** Rim body: outline minus full-width ingress bay, cord-under, and inner bore. */
export function piecePath(piece, ty) {
  const outline = piece.points
    ? lPath(piece.points, ty)
    : rectPath(piece.x, piece.z, piece.w, piece.h, ty);
  const cuts = [];
  for (const s of featureShapes(piece)) {
    if (s.kind === "ingress" || s.kind === "under") {
      cuts.push(rectPath(s.x, s.z, s.w, s.h, ty));
    } else if (s.kind === "hole") {
      cuts.push(circlePath(s.cx, s.cz, s.inner_r, ty));
    }
  }
  return [outline, ...cuts].join(" ");
}

/** Ingress U (arms + back) drawn in the glass, same fill as the piece. */
export function ingressUPath(piece, ty) {
  const parts = featureShapes(piece)
    .filter((s) => s.kind === "ingress-arm" || s.kind === "ingress-back")
    .map((s) => rectPath(s.x, s.z, s.w, s.h, ty));
  return parts.join(" ");
}

/** Outer-Ø boss minus inner bore, fused to the inner rim edge. */
export function cordBossPath(piece, ty) {
  const parts = [];
  for (const s of featureShapes(piece)) {
    if (s.kind !== "hole") continue;
    parts.push(circlePath(s.cx, s.cz, s.outer_r, ty));
    parts.push(circlePath(s.cx, s.cz, s.inner_r, ty));
  }
  return parts.join(" ");
}
