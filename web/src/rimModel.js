// Feature vectors, BOM, and OpenSCAD export for a rectangular rim lid.
// Mirrors rim_feat() / RIM_FEAT_NONE in rim_rectangular_lid.scad.

import {
  EDGE_PROFILE_MAX_X,
  RIM_MAX_PIECE_LEN,
  autoCornerLeg,
  blowoutGapSize,
  layoutPieces,
  sideSegments,
} from "./blowoutLayout.js";

export const SIDE_NAMES = ["South", "East", "North", "West"];
export const SIDE_SHORT = ["S", "E", "N", "W"];
export const CORNER_NAMES = ["SW", "SE", "NE", "NW"];
export const CORNER_ARM_HINT = {
  0: { a: "west arm", b: "south arm" },
  1: { a: "east arm", b: "south arm" },
  2: { a: "east arm", b: "north arm" },
  3: { a: "west arm", b: "north arm" },
};

export const FEATURE_MODES = [
  { value: "none", label: "None" },
  { value: "cord_hole", label: "Cord hole" },
  { value: "cord_under", label: "Cord under" },
  { value: "ingress", label: "Lid ingress" },
  { value: "combine", label: "Combine features" },
];

export const CORD_POS_OPTIONS = [
  { value: "left", label: "Left" },
  { value: "middle", label: "Middle" },
  { value: "right", label: "Right" },
];

export function emptyFeat() {
  return {
    cord_hole: false,
    cord_hole_inner_d: 6,
    cord_hole_pos: "middle",
    cord_under: false,
    cord_under_gap_len: 20,
    lid_ingress: false,
    ingress_opening: 40,
    ingress_depth: 30,
    ingress_on: "a",
    cord_hole_on: "a",
    cord_under_on: "a",
  };
}

export function cloneFeat(f = emptyFeat()) {
  return { ...emptyFeat(), ...f };
}

export function emptyCorners() {
  return [0, 1, 2, 3].map(() => emptyFeat());
}

export function emptySides() {
  return [[], [], [], []];
}

export function ingressPad() {
  return 2 * EDGE_PROFILE_MAX_X;
}

export function ingressBay(opening) {
  return opening > 0 ? opening + ingressPad() : 0;
}

export function featHasIngress(f) {
  return Boolean(f?.lid_ingress && f.ingress_opening > 0);
}

export function featActive(f) {
  return Boolean(f?.cord_hole || f?.cord_under || featHasIngress(f));
}

export function featureMode(f) {
  const n = [f?.cord_hole, f?.cord_under, featHasIngress(f)].filter(Boolean).length;
  if (n === 0) return "none";
  if (n > 1) return "combine";
  if (f.cord_hole) return "cord_hole";
  if (f.cord_under) return "cord_under";
  return "ingress";
}

export function applyFeatureMode(f, mode) {
  const next = cloneFeat(f);
  if (mode === "combine") return next;
  next.cord_hole = mode === "cord_hole";
  next.cord_under = mode === "cord_under";
  next.lid_ingress = mode === "ingress";
  if (mode === "ingress" && !(next.ingress_opening > 0)) next.ingress_opening = 40;
  return next;
}

export function cornerFeatMinLeg(f, baseLeg) {
  return featHasIngress(f) ? Math.max(baseLeg, ingressBay(f.ingress_opening) + 4) : baseLeg;
}

export function effectiveCornerLeg(gw, gd, corners = emptyCorners()) {
  const base = autoCornerLeg(gw, gd);
  let need = base;
  for (const c of corners) need = Math.max(need, cornerFeatMinLeg(c, base));
  return need;
}

export function syncSideFeats(gw, gd, corners, prevSides = emptySides()) {
  const leg = effectiveCornerLeg(gw, gd, corners);
  return [0, 1, 2, 3].map((si) => {
    const n = sideSegments(si, gw, gd, leg).length;
    const prev = prevSides[si] || [];
    return Array.from({ length: n }, (_, i) => cloneFeat(prev[i]));
  });
}

export function featSummary(f, { corner = false, cornerIdx = 0 } = {}) {
  if (!featActive(f)) return "None";
  const bits = [];
  const arm = (on) => {
    if (!corner) return "";
    const hint = CORNER_ARM_HINT[cornerIdx]?.[on] || `arm ${on}`;
    return ` on ${on.toUpperCase()} (${hint})`;
  };
  if (f.cord_hole) {
    bits.push(`Cord hole Ø${f.cord_hole_inner_d} ${f.cord_hole_pos}${arm(f.cord_hole_on)}`);
  }
  if (f.cord_under) {
    bits.push(`Cord under ${f.cord_under_gap_len} mm${arm(f.cord_under_on)}`);
  }
  if (featHasIngress(f)) {
    const bay = ingressBay(f.ingress_opening);
    bits.push(
      `Ingress opening ${f.ingress_opening} mm (bay ${bay.toFixed(0)} mm)${arm(f.ingress_on)}`
    );
  }
  return bits.join(" · ");
}

export function ingressFits(f, pieceLen) {
  if (!featHasIngress(f)) return true;
  return ingressBay(f.ingress_opening) + 4 <= pieceLen;
}

export function featKey(f) {
  if (!featActive(f)) return "none";
  return [
    f.cord_hole ? `h:${f.cord_hole_inner_d}:${f.cord_hole_pos}:${f.cord_hole_on}` : "",
    f.cord_under ? `u:${f.cord_under_gap_len}:${f.cord_under_on}` : "",
    featHasIngress(f) ? `i:${f.ingress_opening}:${f.ingress_depth}:${f.ingress_on}` : "",
  ].join("|");
}

export function buildLid(gw, gd, corners, sides, layout = "blowout") {
  const leg = effectiveCornerLeg(gw, gd, corners);
  const pieces = layoutPieces(gw, gd, { layout, corners, sides, leg });
  const gap = layout === "blowout" ? blowoutGapSize() : 0;
  return { pieces, gap, leg, W: EDGE_PROFILE_MAX_X, gw, gd, layout };
}

export function bomLines(pieces) {
  const map = new Map();
  const seen = new Set();
  for (const p of pieces) {
    if (seen.has(p.id)) continue;
    seen.add(p.id);
    const key = [
      p.kind,
      p.length,
      p.lengthB ?? "",
      p.joinCode,
      featKey(p.feat),
    ].join("/");
    if (!map.has(key)) {
      map.set(key, {
        key,
        kind: p.kind,
        name: p.kind === "corner" ? "Corner L" : "Straight",
        labels: [],
        length: p.length,
        lengthB: p.lengthB,
        joins: p.joins,
        joinCode: p.joinCode,
        features: featSummary(p.feat, {
          corner: p.kind === "corner",
          cornerIdx: p.cornerIdx ?? 0,
        }),
        feat: p.feat,
        qty: 0,
        printMm: p.kind === "corner" ? p.length + p.lengthB : p.length,
      });
    }
    const row = map.get(key);
    row.qty += 1;
    row.labels.push(p.label);
  }
  return [...map.values()].map((row) => ({
    ...row,
    piece: row.labels.join(", "),
  }));
}

export function bomTotals(lines) {
  let corners = 0;
  let straights = 0;
  let featured = 0;
  let printMm = 0;
  for (const row of lines) {
    if (row.kind === "corner") corners += row.qty;
    else straights += row.qty;
    if (featActive(row.feat)) featured += row.qty;
    printMm += row.printMm * row.qty;
  }
  return {
    corners,
    straights,
    featured,
    pieces: corners + straights,
    printMm,
    stls: corners + straights,
  };
}

export function toPrintParts(lines) {
  const parts = [];
  for (const row of lines) {
    if (row.kind === "corner") {
      parts.push({ kind: "corner", qty: row.qty });
      continue;
    }
    const f = row.feat;
    parts.push({
      kind: "edge",
      qty: row.qty,
      length: row.length,
      edge_join_ends: row.joinCode,
      cornerpiecenum: 0,
      cord_hole: Boolean(f.cord_hole),
      cord_hole_inner_d: f.cord_hole_inner_d,
      cord_hole_pos: f.cord_hole_pos,
      cord_under: Boolean(f.cord_under),
      cord_under_gap_len: f.cord_under_gap_len,
      lid_ingress: featHasIngress(f),
      ingress_depth: f.ingress_depth,
      ingress_length: featHasIngress(f) ? ingressBay(f.ingress_opening) : 40,
      ingress_remove_right_rim: false,
    });
  }
  return parts;
}

function scadFeat(f) {
  if (!featActive(f)) return "RIM_FEAT_NONE";
  const args = [];
  if (f.cord_hole) {
    args.push(
      `cord_hole = true`,
      `cord_d = ${f.cord_hole_inner_d}`,
      `cord_pos = "${f.cord_hole_pos}"`,
      `cord_on = "${f.cord_hole_on}"`
    );
  }
  if (f.cord_under) {
    args.push(
      `cord_under = true`,
      `under_gap = ${f.cord_under_gap_len}`,
      `under_on = "${f.cord_under_on}"`
    );
  }
  if (featHasIngress(f)) {
    args.push(
      `ingress = true`,
      `ingress_len = ${f.ingress_opening}`,
      `ingress_dep = ${f.ingress_depth}`,
      `ingress_on = "${f.ingress_on}"`
    );
  }
  return `rim_feat(${args.join(", ")})`;
}

function scadList(feats) {
  if (!feats.length) return "[]";
  return `[\n    ${feats.map(scadFeat).join(",\n    ")}\n]`;
}

export function rimScadSource({ gw, gd, layout, corners, sides }) {
  return `// Generated by the aquarium lid web builder
RIM_RECT_LIB_ONLY = true;
include <rim_rectangular_lid.scad>

corner_features = [
    ${corners.map(scadFeat).join(",\n    ")}
];

side_features_s = ${scadList(sides[0])};
side_features_e = ${scadList(sides[1])};
side_features_n = ${scadList(sides[2])};
side_features_w = ${scadList(sides[3])};

rim_rectangular_lid(
    glass_w = ${gw},
    glass_d = ${gd},
    layout  = "${layout}",
    corners = corner_features,
    side_feats_s = side_features_s,
    side_feats_e = side_features_e,
    side_feats_n = side_features_n,
    side_feats_w = side_features_w
);
`;
}

export function bomCsv(lines) {
  const header = ["Piece", "Type", "Qty", "Length (mm)", "End joins", "Features"];
  const rows = lines.map((row) => {
    const len =
      row.kind === "corner"
        ? `${row.length} × ${row.lengthB}`
        : String(row.length);
    return [row.piece, row.name, row.qty, len, row.joins, row.features].map((c) =>
      `"${String(c).replaceAll('"', '""')}"`
    );
  });
  return [header.join(","), ...rows.map((r) => r.join(","))].join("\n");
}

export function demoFeatures() {
  const opening = 40;
  const corners = [
    { ...emptyFeat(), lid_ingress: true, ingress_opening: opening, ingress_depth: 30, ingress_on: "a" },
    { ...emptyFeat(), cord_hole: true, cord_hole_inner_d: 8, cord_hole_pos: "middle", cord_hole_on: "b" },
    { ...emptyFeat(), cord_under: true, cord_under_gap_len: 24, cord_under_on: "a" },
    { ...emptyFeat(), lid_ingress: true, ingress_opening: opening, ingress_depth: 30, ingress_on: "b" },
  ];
  const sides = [
    [
      { ...emptyFeat(), lid_ingress: true, ingress_opening: opening, ingress_depth: 30 },
      { ...emptyFeat(), cord_under: true, cord_under_gap_len: 20 },
      { ...emptyFeat(), cord_hole: true, cord_hole_inner_d: 8, cord_hole_pos: "left" },
    ],
    [{ ...emptyFeat(), cord_hole: true, cord_hole_inner_d: 10, cord_hole_pos: "right" }],
    [
      emptyFeat(),
      { ...emptyFeat(), cord_under: true, cord_under_gap_len: 28 },
      { ...emptyFeat(), cord_hole: true, cord_hole_inner_d: 6, cord_hole_pos: "middle" },
    ],
    [{ ...emptyFeat(), lid_ingress: true, ingress_opening: opening, ingress_depth: 30 }],
  ];
  return { gw: 900, gd: 600, corners, sides };
}

export { RIM_MAX_PIECE_LEN };
