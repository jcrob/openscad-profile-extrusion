// Mirrors rim_rectangular_lid.scad planning + blowout offset math (XZ plane).

export const EDGE_PROFILE_MAX_X = 29.2; // 2.8+3.4+6 + 6 + 11
export const SPLINE_W = 12.2; // inner spline / no-right-rim width (stem_root_right)
export const RIM_MAX_PIECE_LEN = 200;
export const RIM_CORNER_SPLIT = 400;
export const RIM_LAYOUT_GAP = 12;

export function cornerLegForDim(dim, maxLen = RIM_MAX_PIECE_LEN, split = RIM_CORNER_SPLIT) {
  return dim <= split ? dim / 2 : maxLen;
}

export function autoCornerLeg(gw, gd) {
  return Math.max(
    EDGE_PROFILE_MAX_X + 1,
    Math.min(cornerLegForDim(gw), cornerLegForDim(gd))
  );
}

export function straightSegments(runLen, maxLen = RIM_MAX_PIECE_LEN) {
  if (runLen <= 0) return [];
  const nFull = Math.floor(runLen / maxLen);
  const partial = runLen - nFull * maxLen;
  if (nFull === 0) return [runLen];
  const segs = Array.from({ length: nFull }, () => maxLen);
  if (partial > 0) segs.push(partial);
  return segs;
}

export function sideSegments(sideIdx, gw, gd, leg = autoCornerLeg(gw, gd)) {
  const dim = sideIdx === 0 || sideIdx === 2 ? gw : gd;
  return straightSegments(Math.max(0, dim - 2 * leg));
}

export function blowoutGapSize(layoutGap = RIM_LAYOUT_GAP * 2, blowoutGap = 0) {
  return blowoutGap > 0 ? blowoutGap : layoutGap + EDGE_PROFILE_MAX_X;
}

/** Far-axis explode: gap × (segment count + 1). 0 = X-run (S/N), 1 = Z-run (E/W). */
export function sideAxisGap(si, gw, gd, gap, leg) {
  return gap * (sideSegments(si, gw, gd, leg ?? autoCornerLeg(gw, gd)).length + 1);
}

/** [gx, gz] from the fixed NW corner. */
export function axisGaps(gw, gd, gap, leg) {
  const L = leg ?? autoCornerLeg(gw, gd);
  return [sideAxisGap(0, gw, gd, gap, L), sideAxisGap(1, gw, gd, gap, L)];
}

/** NW stays at (−gap, +gap). Other corners use gx along X and gz along Z. */
export function cornerOffset(ci, gap, gw, gd, leg) {
  const [gx, gz] = axisGaps(gw, gd, gap, leg);
  if (ci === 0) return [-gap, -gz];
  if (ci === 1) return [gx, -gz];
  if (ci === 2) return [gx, gap];
  return [-gap, gap];
}

/** Each side copies its clockwise-start corner (S←SW, E←SE, N←NE, W←NW). */
export function sideOffset(si, gap, gw, gd, leg) {
  const [gx, gz] = axisGaps(gw, gd, gap, leg);
  if (si === 0) return [-gap, -gz];
  if (si === 1) return [gx, -gz];
  if (si === 2) return [gx, gap];
  return [-gap, gap];
}

export function alongExtra(segIdx, gap) {
  return (segIdx + 1) * gap;
}

/** Complete L outline + arm slots for one corner (world XZ). */
export function cornerDraw(ci, x, z, leg, W = EDGE_PROFILE_MAX_X) {
  let points;
  let a;
  let b;
  if (ci === 0) {
    // SW: A west (+Z), B south (+X)
    points = [
      [x - W, z - W],
      [x + leg, z - W],
      [x + leg, z],
      [x, z],
      [x, z + leg],
      [x - W, z + leg],
    ];
    b = makeArm(x, z - W, leg, W, "x", 1, 0, 0, 1);
    a = makeArm(x - W, z, W, leg, "z", 0, 1, 1, 0);
  } else if (ci === 1) {
    // SE: A east (+Z), B south (−X from miter)
    points = [
      [x + W, z - W],
      [x + W, z + leg],
      [x, z + leg],
      [x, z],
      [x - leg, z],
      [x - leg, z - W],
    ];
    b = makeArm(x - leg, z - W, leg, W, "x", -1, 0, 0, 1);
    a = makeArm(x, z, W, leg, "z", 0, 1, -1, 0);
  } else if (ci === 2) {
    // NE: A east (−Z), B north (−X)
    points = [
      [x + W, z + W],
      [x - leg, z + W],
      [x - leg, z],
      [x, z],
      [x, z - leg],
      [x + W, z - leg],
    ];
    b = makeArm(x - leg, z, leg, W, "x", -1, 0, 0, -1);
    a = makeArm(x, z - leg, W, leg, "z", 0, -1, -1, 0);
  } else {
    // NW: A west (−Z), B north (+X)
    points = [
      [x - W, z + W],
      [x - W, z - leg],
      [x, z - leg],
      [x, z],
      [x + leg, z],
      [x + leg, z + W],
    ];
    b = makeArm(x, z, leg, W, "x", 1, 0, 0, -1);
    a = makeArm(x - W, z - leg, W, leg, "z", 0, -1, 1, 0);
  }
  const xs = points.map((p) => p[0]);
  const zs = points.map((p) => p[1]);
  const minX = Math.min(...xs);
  const minZ = Math.min(...zs);
  return {
    points,
    arms: { a, b },
    x: minX,
    z: minZ,
    w: Math.max(...xs) - minX,
    h: Math.max(...zs) - minZ,
    labelX: x + (ci === 1 || ci === 2 ? -leg / 3 : leg / 3),
    labelZ: z + (ci === 2 || ci === 3 ? W / 2 : -W / 2),
  };
}

export function straightDraw(si, x, z, w, h) {
  let arm;
  if (si === 0) arm = makeArm(x, z, w, h, "x", 1, 0, 0, 1);
  else if (si === 1) arm = makeArm(x, z, w, h, "z", 0, 1, -1, 0);
  else if (si === 2) arm = makeArm(x, z, w, h, "x", -1, 0, 0, -1);
  else arm = makeArm(x, z, w, h, "z", 0, -1, 1, 0);
  return { x, z, w, h, arms: { a: arm }, points: null };
}

function makeArm(x, z, w, h, axis, dirX, dirZ, inX, inZ) {
  const length = axis === "x" ? w : h;
  const thick = axis === "x" ? h : w;
  if (axis === "x") {
    return {
      x,
      z,
      w,
      h,
      axis,
      length,
      thick,
      mx: dirX > 0 ? x : x + w,
      mz: z + h / 2,
      dx: dirX * length,
      dz: 0,
      inX,
      inZ,
      innerAt: inZ > 0 ? z + h : z,
    };
  }
  return {
    x,
    z,
    w,
    h,
    axis,
    length,
    thick,
    mx: x + w / 2,
    mz: dirZ > 0 ? z : z + h,
    dx: 0,
    dz: dirZ * length,
    inX,
    inZ,
    innerAt: inX > 0 ? x + w : x,
  };
}

export function straightJoins(segIdx, segCount) {
  if (segCount === 1) return { code: 2, label: "male / male" };
  if (segIdx === 0) return { code: 1, label: "male / female" };
  if (segIdx === segCount - 1) return { code: 2, label: "male / male" };
  return { code: 1, label: "male / female" };
}

/**
 * Schematic piece rectangles in XZ (z is the second coord).
 * Thickness is drawn outward from the glass rectangle.
 * layout "assembled" keeps pieces on the glass; "blowout" explodes them.
 */
export function layoutPieces(gw, gd, opts = {}) {
  const layout = opts.layout === "assembled" ? "assembled" : "blowout";
  const corners = opts.corners ?? [null, null, null, null];
  const sides = opts.sides ?? [[], [], [], []];
  const explode = layout === "blowout";
  const gap = explode ? blowoutGapSize() : 0;
  const leg = opts.leg ?? autoCornerLeg(gw, gd);
  const W = EDGE_PROFILE_MAX_X;
  const pieces = [];

  const cornerDefs = [
    { ci: 0, x: 0, z: 0, hx: 1, hz: 1, label: "SW" },
    { ci: 1, x: gw, z: 0, hx: -1, hz: 1, label: "SE" },
    { ci: 2, x: gw, z: gd, hx: -1, hz: -1, label: "NE" },
    { ci: 3, x: 0, z: gd, hx: 1, hz: -1, label: "NW" },
  ];

  for (const c of cornerDefs) {
    const [ox, oz] = explode ? cornerOffset(c.ci, gap, gw, gd, leg) : [0, 0];
    const x = c.x + ox;
    const z = c.z + oz;
    const feat = corners[c.ci] ?? {};
    const joins = { code: 2, label: "female / female" };
    const drawn = cornerDraw(c.ci, x, z, leg, W);
    pieces.push({
      id: `corner-${c.ci}`,
      kind: "corner",
      cornerIdx: c.ci,
      label: c.label,
      length: leg,
      lengthB: leg,
      joins: joins.label,
      joinCode: joins.code,
      feat,
      ...drawn,
      rowZ: z,
      colX: x,
    });
  }

  const sideDefs = [
    { si: 0, name: "S", along: "x" },
    { si: 1, name: "E", along: "z" },
    { si: 2, name: "N", along: "x" },
    { si: 3, name: "W", along: "z" },
  ];

  for (const side of sideDefs) {
    const segs = sideSegments(side.si, gw, gd, leg);
    const [ox, oz] = explode ? sideOffset(side.si, gap, gw, gd, leg) : [0, 0];
    let acc = 0;
    segs.forEach((len, i) => {
      const extra = explode ? alongExtra(i, gap) : 0;
      const feat = sides[side.si]?.[i] ?? {};
      const joins = straightJoins(i, segs.length);
      const base = {
        id: `side-${side.si}-${i}`,
        kind: "straight",
        sideIdx: side.si,
        segIdx: i,
        label: `${side.name}${i + 1}`,
        length: len,
        joins: joins.label,
        joinCode: joins.code,
        feat,
      };
      if (side.si === 0) {
        const x = leg + acc + extra + ox;
        const z = 0 + oz;
        pieces.push({
          ...base,
          ...straightDraw(0, x, z - W, len, W),
          rowZ: z,
          colX: x,
        });
      } else if (side.si === 1) {
        const x = gw + ox;
        const z = leg + acc + extra + oz;
        pieces.push({
          ...base,
          ...straightDraw(1, x, z, W, len),
          rowZ: z,
          colX: x,
        });
      } else if (side.si === 2) {
        const x = gw - leg - acc - extra - len + ox;
        const z = gd + oz;
        pieces.push({
          ...base,
          ...straightDraw(2, x, z, len, W),
          rowZ: z,
          colX: x,
        });
      } else {
        const x = 0 + ox;
        const z = gd - leg - acc - extra - len + oz;
        pieces.push({
          ...base,
          ...straightDraw(3, x - W, z, W, len),
          rowZ: z,
          colX: x,
        });
      }
      acc += len;
    });
  }

  return pieces;
}

/** Unique logical pieces (one row per corner, not two arms). */
export function logicalPieces(pieces) {
  const seen = new Map();
  for (const p of pieces) {
    if (!seen.has(p.id)) seen.set(p.id, p);
  }
  return [...seen.values()];
}

export function blowoutPieces(gw, gd, gap = blowoutGapSize()) {
  const leg = autoCornerLeg(gw, gd);
  const pieces = layoutPieces(gw, gd, { layout: "blowout", leg });
  return { pieces, gap, leg, W: EDGE_PROFILE_MAX_X, gw, gd };
}

export function alignmentGuides(gw, gd, gap = blowoutGapSize(), leg) {
  const L = leg ?? autoCornerLeg(gw, gd);
  const southZ = sideOffset(0, gap, gw, gd, L)[1];
  const northZ = gd + sideOffset(2, gap, gw, gd, L)[1];
  const eastX = gw + sideOffset(1, gap, gw, gd, L)[0];
  const westX = sideOffset(3, gap, gw, gd, L)[0];
  return { southZ, northZ, eastX, westX, gap };
}
