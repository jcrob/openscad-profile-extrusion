// Top-down plan matching rim_piece_assembly:
// - Ingress: rim U-walls around the inner cut; cavity is wrap background.
// - Cord hole: outer-Ø boss fused to the inner flange edge, inner bore open.
// - Feeding door: spline-width outer U (glass-sit unbroken), inner spline
//   rectangle, hinge on the main rim, sit-on latch on the outer back wall.

import { featHasFeeding, featHasIngress } from "./rimModel.js";
import { SPLINE_W } from "./blowoutLayout.js";

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
      if (s.kind === "ingress" || s.kind === "feeding") {
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

function uCorners(arm, half, depth, inset = 0) {
  const [ix0, iz0] = alongInner(arm, 0.5);
  const ix = ix0 - arm.inX * inset;
  const iz = iz0 - arm.inZ * inset;
  const { ax, az } = armAlong(arm);
  const left = [ix - ax * half, iz - az * half];
  const right = [ix + ax * half, iz + az * half];
  const far = depth + inset;
  return {
    left,
    farL: [left[0] + arm.inX * far, left[1] + arm.inZ * far],
    farR: [right[0] + arm.inX * far, right[1] + arm.inZ * far],
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
  const inset = 1.2;
  return {
    wall,
    opening: innerHalf * 2,
    bay: outerHalf * 2,
    inner: uCorners(arm, innerHalf, innerDepth, inset),
    outer: uCorners(arm, outerHalf, outerDepth, inset),
  };
}

/**
 * Dual spline feeding door: outer U uses inner-spline width (not the glass
 * sit). Glass-sit on the main bar stays continuous. Inner door is a spline
 * rectangle inside the U, hinged on the main rim, latched on the back wall.
 */
export function feedingGeometry(arm, opening, depth) {
  const wall = SPLINE_W;
  const gap = 1.2;
  const innerHalf = Math.min(Math.max(opening, 2), arm.length * 0.9) / 2;
  const outerHalf = Math.min(innerHalf + wall, arm.length * 0.49);
  const innerDepth = Math.max(depth, 8);
  const outerDepth = innerDepth + wall;
  const inset = 1.2;
  const doorOuterHalf = Math.max(innerHalf - gap, wall + 2);
  const doorInnerHalf = Math.max(doorOuterHalf - wall, 2);
  const doorOuterDepth = Math.max(innerDepth - gap, wall * 2 + 4);
  const doorInnerDepth = Math.max(doorOuterDepth - 2 * wall, 4);
  const doorNear = inset - gap;
  return {
    wall,
    opening: innerHalf * 2,
    bay: outerHalf * 2,
    inner: uCorners(arm, innerHalf, innerDepth, inset),
    outer: uCorners(arm, outerHalf, outerDepth, inset),
    doorOuter: uCorners(arm, doorOuterHalf, doorOuterDepth, doorNear),
    doorInner: uCorners(arm, doorInnerHalf, doorInnerDepth, doorNear - wall),
    hinge: {
      a: alongInner(arm, 0.5 - doorOuterHalf / arm.length),
      b: alongInner(arm, 0.5 + doorOuterHalf / arm.length),
    },
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
  if (featHasFeeding(f)) {
    const arm = pickArm(piece, f.feeding_on || "a");
    if (arm) {
      const u = feedingGeometry(
        arm,
        f.feeding_opening,
        Math.max(16, f.feeding_depth || 40)
      );
      shapes.push({ kind: "feeding", ...u, opens: true, hollow: true });
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

export function feedingWallPoints(s) {
  return ingressWallPoints(s);
}

export function feedingDoorFramePoints(s) {
  const o = s.doorOuter;
  const i = s.doorInner;
  return [o.left, o.farL, o.farR, o.right, i.right, i.farR, i.farL, i.left];
}

export function feedingWallPath(piece, ty) {
  return featureShapes(piece)
    .filter((s) => s.kind === "feeding")
    .map((s) => lPath(feedingWallPoints(s), ty))
    .join(" ");
}

export function feedingDoorPath(piece, ty) {
  return featureShapes(piece)
    .filter((s) => s.kind === "feeding")
    .map((s) => lPath(feedingDoorFramePoints(s), ty))
    .join(" ");
}

export function feedingHingePath(piece, ty) {
  return featureShapes(piece)
    .filter((s) => s.kind === "feeding" && s.hinge)
    .map((s) => {
      const [x0, z0] = s.hinge.a;
      const [x1, z1] = s.hinge.b;
      return `M ${x0} ${ty(z0)} L ${x1} ${ty(z1)}`;
    })
    .join(" ");
}

export function feedingLatchPoints(s) {
  const mid = (a, b) => [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2];
  const m = mid(s.inner.farL, s.inner.farR);
  const { ax, az } = armAlongFromQuad(s);
  const hw = 5;
  const sit = 3.2;
  const [ix, iz] = [s.outer.farL[0] - s.inner.farL[0], s.outer.farL[1] - s.inner.farL[1]];
  const len = Math.hypot(ix, iz) || 1;
  const nx = ix / len;
  const nz = iz / len;
  const left = [m[0] - ax * hw + nx * 0.4, m[1] - az * hw + nz * 0.4];
  const right = [m[0] + ax * hw + nx * 0.4, m[1] + az * hw + nz * 0.4];
  const farL = [left[0] + nx * sit, left[1] + nz * sit];
  const farR = [right[0] + nx * sit, right[1] + nz * sit];
  return [left, farL, farR, right];
}

function armAlongFromQuad(s) {
  const dx = s.outer.right[0] - s.outer.left[0];
  const dz = s.outer.right[1] - s.outer.left[1];
  const len = Math.hypot(dx, dz) || 1;
  return { ax: dx / len, az: dz / len };
}

export function feedingLatchPath(piece, ty) {
  return featureShapes(piece)
    .filter((s) => s.kind === "feeding")
    .map((s) => lPath(feedingLatchPoints(s), ty))
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
    if (s.kind === "feeding") {
      const arm = pickArm(piece, piece.feat?.feeding_on || "a");
      if (arm) out.push({ kind: "rect", ...feedingSplineSlot(arm, s.bay) });
      out.push({
        kind: "poly",
        points: [s.inner.left, s.inner.farL, s.inner.farR, s.inner.right],
      });
      out.push({
        kind: "poly",
        points: [s.doorInner.left, s.doorInner.farL, s.doorInner.farR, s.doorInner.right],
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

/** Spline-only gap on the inner flange — glass-sit band of the bar stays solid. */
export function feedingSplineSlot(arm, bay) {
  const half = Math.min(bay, arm.length * 0.9) / 2;
  const [cx, cz] = alongCenter(arm, 0.5);
  const sw = SPLINE_W;
  if (arm.axis === "x") {
    const z0 = Math.min(arm.innerAt, arm.innerAt - arm.inZ * sw);
    return {
      x: cx - half,
      z: z0,
      w: half * 2,
      h: sw,
    };
  }
  const x0 = Math.min(arm.innerAt, arm.innerAt - arm.inX * sw);
  return {
    x: x0,
    z: cz - half,
    w: sw,
    h: half * 2,
  };
}
