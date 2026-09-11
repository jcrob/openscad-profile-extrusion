// Mirrors rim_rectangular_lid.scad blowout offset math (XZ plane).

export const EDGE_PROFILE_MAX_X = 29.2; // 2.8+3.4+6 + 6 + 11
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

export function sideSegments(sideIdx, gw, gd) {
  const leg = autoCornerLeg(gw, gd);
  const dim = sideIdx === 0 || sideIdx === 2 ? gw : gd;
  return straightSegments(Math.max(0, dim - 2 * leg));
}

export function blowoutGapSize(layoutGap = RIM_LAYOUT_GAP * 2, blowoutGap = 0) {
  return blowoutGap > 0 ? blowoutGap : layoutGap + EDGE_PROFILE_MAX_X;
}

/** Far-axis explode: gap × (segment count + 1). 0 = X-run (S/N), 1 = Z-run (E/W). */
export function sideAxisGap(si, gw, gd, gap) {
  return gap * (sideSegments(si, gw, gd).length + 1);
}

/** [gx, gz] from the fixed NW corner. */
export function axisGaps(gw, gd, gap) {
  return [sideAxisGap(0, gw, gd, gap), sideAxisGap(1, gw, gd, gap)];
}

/** NW stays at (−gap, +gap). Other corners use gx along X and gz along Z. */
export function cornerOffset(ci, gap, gw, gd) {
  const [gx, gz] = axisGaps(gw, gd, gap);
  if (ci === 0) return [-gap, -gz];
  if (ci === 1) return [gx, -gz];
  if (ci === 2) return [gx, gap];
  return [-gap, gap];
}

/** Each side copies its clockwise-start corner (S←SW, E←SE, N←NE, W←NW). */
export function sideOffset(si, gap, gw, gd) {
  const [gx, gz] = axisGaps(gw, gd, gap);
  if (si === 0) return [-gap, -gz];
  if (si === 1) return [gx, -gz];
  if (si === 2) return [gx, gap];
  return [-gap, gap];
}

export function alongExtra(segIdx, gap) {
  return (segIdx + 1) * gap;
}

/**
 * Schematic piece rectangles in XZ (z is the second coord).
 * Thickness is drawn outward from the glass rectangle.
 */
export function blowoutPieces(gw, gd, gap = blowoutGapSize()) {
  const leg = autoCornerLeg(gw, gd);
  const W = EDGE_PROFILE_MAX_X;
  const pieces = [];

  const corners = [
    { ci: 0, x: 0, z: 0, hx: 1, hz: 1, label: "SW" },
    { ci: 1, x: gw, z: 0, hx: -1, hz: 1, label: "SE" },
    { ci: 2, x: gw, z: gd, hx: -1, hz: -1, label: "NE" },
    { ci: 3, x: 0, z: gd, hx: 1, hz: -1, label: "NW" },
  ];

  for (const c of corners) {
    const [ox, oz] = cornerOffset(c.ci, gap, gw, gd);
    const x = c.x + ox;
    const z = c.z + oz;
    pieces.push({
      kind: "corner-h",
      label: c.label,
      x: c.hx > 0 ? x : x - leg,
      z: c.hz > 0 ? z - W : z,
      w: leg,
      h: W,
      rowZ: z,
      colX: x,
    });
    pieces.push({
      kind: "corner-v",
      label: c.label,
      x: c.hx > 0 ? x - W : x,
      z: c.hz > 0 ? z : z - leg,
      w: W,
      h: leg,
      rowZ: z,
      colX: x,
    });
  }

  const sides = [
    { si: 0, name: "S", along: "x" },
    { si: 1, name: "E", along: "z" },
    { si: 2, name: "N", along: "x" },
    { si: 3, name: "W", along: "z" },
  ];

  for (const side of sides) {
    const segs = sideSegments(side.si, gw, gd);
    const [ox, oz] = sideOffset(side.si, gap, gw, gd);
    let acc = 0;
    segs.forEach((len, i) => {
      const extra = alongExtra(i, gap);
      if (side.si === 0) {
        const x = leg + acc + extra + ox;
        const z = 0 + oz;
        pieces.push({
          kind: "straight",
          label: `S${i + 1}`,
          x,
          z: z - W,
          w: len,
          h: W,
          rowZ: z,
          colX: x,
        });
      } else if (side.si === 1) {
        const x = gw + ox;
        const z = leg + acc + extra + oz;
        pieces.push({
          kind: "straight",
          label: `E${i + 1}`,
          x,
          z,
          w: W,
          h: len,
          rowZ: z,
          colX: x,
        });
      } else if (side.si === 2) {
        const x = gw - leg - acc - extra - len + ox;
        const z = gd + oz;
        pieces.push({
          kind: "straight",
          label: `N${i + 1}`,
          x,
          z,
          w: len,
          h: W,
          rowZ: z,
          colX: x,
        });
      } else {
        const x = 0 + ox;
        const z = gd - leg - acc - extra - len + oz;
        pieces.push({
          kind: "straight",
          label: `W${i + 1}`,
          x: x - W,
          z,
          w: W,
          h: len,
          rowZ: z,
          colX: x,
        });
      }
      acc += len;
    });
  }

  return { pieces, gap, leg, W, gw, gd };
}

export function alignmentGuides(gw, gd, gap = blowoutGapSize()) {
  const southZ = sideOffset(0, gap, gw, gd)[1];
  const northZ = gd + sideOffset(2, gap, gw, gd)[1];
  const eastX = gw + sideOffset(1, gap, gw, gd)[0];
  const westX = sideOffset(3, gap, gw, gd)[0];
  return { southZ, northZ, eastX, westX, gap };
}
