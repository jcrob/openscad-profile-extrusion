// Top-down SVG geometry: complete L-corners, real-scale features, full frame.

import { featHasIngress, ingressBay } from "./rimModel.js";

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

function posT(pos) {
  if (pos === "left") return 1 / 3;
  if (pos === "right") return 2 / 3;
  return 0.5;
}

function alongPoint(arm, t) {
  return [arm.mx + arm.dx * t, arm.mz + arm.dz * t];
}

function notchRect(arm, width, depth, t = 0.5) {
  const half = Math.min(width, arm.length * 0.92) / 2;
  const d = Math.min(depth, arm.thick - 1.5);
  const [cx, cz] = alongPoint(arm, t);
  if (arm.axis === "x") {
    const x0 = cx - half;
    const z0 = arm.inZ > 0 ? arm.innerAt - d : arm.innerAt;
    return { x: x0, z: z0, w: half * 2, h: d };
  }
  const z0 = cz - half;
  const x0 = arm.inX > 0 ? arm.innerAt - d : arm.innerAt;
  return { x: x0, z: z0, w: d, h: half * 2 };
}

export function featureShapes(piece) {
  const f = piece.feat || {};
  const shapes = [];
  const pickArm = (on) => {
    if (piece.kind === "corner") return piece.arms?.[on] || piece.arms?.a;
    return piece.arms?.a;
  };

  if (featHasIngress(f)) {
    const arm = pickArm(f.ingress_on || "a");
    if (arm) {
      const bay = ingressBay(f.ingress_opening);
      const depth = Math.min(arm.thick * 0.88, Math.max(8, f.ingress_depth || arm.thick * 0.75));
      shapes.push({ kind: "ingress", ...notchRect(arm, bay, depth, 0.5) });
    }
  }
  if (f.cord_under) {
    const arm = pickArm(f.cord_under_on || "a");
    if (arm) {
      const gap = Math.max(6, f.cord_under_gap_len || 20);
      shapes.push({ kind: "under", ...notchRect(arm, gap, arm.thick * 0.42, 0.5) });
    }
  }
  if (f.cord_hole) {
    const arm = pickArm(f.cord_hole_on || "a");
    if (arm) {
      const [cx, cz] = alongPoint(arm, posT(f.cord_hole_pos));
      const r = Math.max(2.5, (f.cord_hole_inner_d || 6) / 2);
      shapes.push({ kind: "hole", cx, cz, r });
    }
  }
  return shapes;
}
