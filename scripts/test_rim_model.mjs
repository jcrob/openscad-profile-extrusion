import assert from "node:assert/strict";
import {
  alignmentGuides,
  autoCornerLeg,
  blowoutGapSize,
  cornerDraw,
  cornerOffset,
  sideOffset,
  sideSegments,
} from "../web/src/blowoutLayout.js";
import { featureShapes, piecePath, worldBounds } from "../web/src/rimDraw.js";
import {
  applyFeatureMode,
  bomLines,
  bomTotals,
  buildLid,
  demoFeatures,
  emptyCorners,
  emptyFeat,
  emptySides,
  featSummary,
  featureMode,
  ingressBay,
  rimScadSource,
  syncSideFeats,
  toPrintParts,
} from "../web/src/rimModel.js";

function checkOffsets(gw, gd, label) {
  const gap = blowoutGapSize();
  const leg = autoCornerLeg(gw, gd);
  const ns = sideSegments(0, gw, gd, leg).length;
  const ne = sideSegments(1, gw, gd, leg).length;
  const sw = cornerOffset(0, gap, gw, gd, leg);
  const se = cornerOffset(1, gap, gw, gd, leg);
  const south = sideOffset(0, gap, gw, gd, leg);
  const east = sideOffset(1, gap, gw, gd, leg);
  assert.equal(sw[1], south[1], `${label} south Z`);
  assert.equal(se[0], east[0], `${label} east X`);
  assert.equal(se[0], gap * (ns + 1), `${label} gx`);
  assert.equal(-sw[1], gap * (ne + 1), `${label} gz`);
}

checkOffsets(600, 450, "default");
checkOffsets(900, 600, "demo");

const empty900 = buildLid(900, 600, emptyCorners(), syncSideFeats(900, 600, emptyCorners(), emptySides()), "blowout");
const emptyLines = bomLines(empty900.pieces);
const emptyTot = bomTotals(emptyLines);
assert.equal(emptyTot.corners, 4, "4 corners");
assert.equal(emptyTot.straights, 8, "3+1+3+1 straights");
assert.equal(emptyTot.featured, 0);

const assembled = buildLid(900, 600, emptyCorners(), empty900.pieces && syncSideFeats(900, 600, emptyCorners(), emptySides()), "assembled");
const swBlow = empty900.pieces.find((p) => p.label === "SW");
const swAsm = assembled.pieces.find((p) => p.label === "SW");
assert.ok(swBlow.x !== swAsm.x || swBlow.z !== swAsm.z, "blowout moves SW");
assert.equal(assembled.gap, 0);

const demo = demoFeatures();
const demoSides = syncSideFeats(demo.gw, demo.gd, demo.corners, demo.sides);
const demoLid = buildLid(demo.gw, demo.gd, demo.corners, demoSides, "blowout");
const demoLines = bomLines(demoLid.pieces);
const demoTot = bomTotals(demoLines);
assert.equal(demoTot.pieces, 12);
assert.ok(demoTot.featured >= 9, `featured demo pieces, got ${demoTot.featured}`);
assert.match(featSummary(demo.corners[0], { corner: true, cornerIdx: 0 }), /Ingress/);
assert.equal(featureMode(applyFeatureMode(emptyFeat(), "cord_hole")), "cord_hole");

const parts = toPrintParts(demoLines);
assert.ok(parts.some((p) => p.kind === "edge" && p.lid_ingress));
assert.ok(parts.some((p) => p.kind === "corner" && p.qty >= 1));

const scad = rimScadSource({
  gw: demo.gw,
  gd: demo.gd,
  layout: "assembled",
  corners: demo.corners,
  sides: demoSides,
});
assert.match(scad, /layout\s+= "assembled"/);
assert.match(scad, /rim_feat\(ingress = true/);

const fat = applyFeatureMode(emptyFeat(), "ingress");
fat.ingress_opening = 160;
const fatCorners = [fat, emptyFeat(), emptyFeat(), emptyFeat()];
const fatLid = buildLid(900, 600, fatCorners, syncSideFeats(900, 600, fatCorners, emptySides()), "assembled");
assert.ok(fatLid.leg > 200, `ingress grows corner leg, got ${fatLid.leg}`);
assert.ok(ingressBay(160) + 4 <= fatLid.leg);

const guides = alignmentGuides(900, 600, blowoutGapSize(), autoCornerLeg(900, 600));
assert.ok(guides.eastX > 900);

const swL = cornerDraw(0, 0, 0, 200, 29.2);
assert.equal(swL.points.length, 6, "complete L has 6 vertices");
assert.ok(swL.z < 0 && swL.x < 0, "SW L includes outer south and west");
assert.ok(swL.w > 200 && swL.h > 200, "SW L bbox is both arms");

const south = assembled.pieces.find((p) => p.label === "S1");
assert.ok(south && south.z < 0, "south straight sits below glass");
const frame = worldBounds(assembled.pieces, 900, 600, 56);
assert.ok(frame.minZ < south.z, "frame includes south draw-out");
assert.ok(frame.ty(south.z) < frame.vbH, "south maps inside SVG viewBox");
assert.match(frame.viewBox, / 0 /);

const swFeat = featureShapes({
  kind: "corner",
  feat: demo.corners[0],
  arms: swL.arms,
});
const ingress = swFeat.find((s) => s.kind === "ingress");
assert.ok(ingress && Math.max(ingress.w, ingress.h) > 40, "SW ingress drawn on arm");
assert.ok(ingress.fullWidth, "ingress removes the full rim width");
assert.ok(swFeat.some((s) => s.kind === "ingress-back"), "ingress U back in the glass");

const holePiece = {
  kind: "corner",
  feat: demo.corners[1],
  arms: cornerDraw(1, 900, 0, 200, 29.2).arms,
};
const hole = featureShapes(holePiece).find((s) => s.kind === "hole");
assert.ok(hole, "cord hole");
assert.ok(hole.outer_r > hole.inner_r, "outer diameter around the bore");
assert.ok(hole.cz > -2 && hole.cz < 12, "outer Ø connects at the inner rim edge");
assert.ok(hole.cx > 700 && hole.cx < 900, "hole along the SE south arm");

const d = piecePath({ ...swL, kind: "corner", feat: demo.corners[0] }, (z) => -z);
assert.match(d, /^M /);
assert.ok(d.includes("H ") || d.includes("L "), "path has outline + cut");

console.log("ok  rim model + assembled/blowout + BOM checks passed");
