import assert from "node:assert/strict";
import {
  alignmentGuides,
  autoCornerLeg,
  blowoutGapSize,
  cornerDraw,
  cornerOffset,
  sideOffset,
  sideSegments,
  SPLINE_W,
} from "../web/src/blowoutLayout.js";
import {
  featureShapes,
  feedingDoorFramePoints,
  feedingGeometry,
  feedingSplineSlot,
  feedingWallPoints,
  ingressWallPath,
  ingressWallPoints,
  openingFills,
  outlinePoints,
  piecePath,
  worldBounds,
} from "../web/src/rimDraw.js";
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
  feedingBay,
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
assert.ok(ingress && ingress.hollow && ingress.bay > ingress.opening, "SW hollow ingress U");
assert.ok(ingress.inner.farL[0] > ingress.inner.left[0], "U opens into the glass");
assert.ok(ingress.outer.span > ingress.inner.span, "rim wall around the inner cut");
assert.ok(ingress.outer.depth > ingress.inner.depth, "back wall beyond the cavity");
const swOutline = outlinePoints({ ...swL, kind: "corner", feat: demo.corners[0] });
assert.equal(swOutline.length, 6, "L outline stays the bar; U is a separate wall");
const swWallPts = ingressWallPoints(ingress);
assert.equal(swWallPts.length, 8, "U wall is a single 8-point ribbon");
assert.ok(swWallPts[1][0] > swWallPts[0][0], "outer wall goes into the glass");
const swWall = ingressWallPath({ ...swL, kind: "corner", feat: demo.corners[0] }, (z) => -z);
assert.match(swWall, /^M /);
assert.ok(!swWall.includes(" Z M "), "U wall is one subpath, not even-odd quads");

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

const swPiece = demoLid.pieces.find((p) => p.label === "SW");
const swOpens = openingFills(swPiece);
assert.ok(
  swOpens.some((s) => s.kind === "poly" && s.points.length === 4),
  "ingress cavity is filled with background"
);
const swSlot = swOpens.find((s) => s.kind === "rect");
assert.ok(swSlot, "main-length ingress gap is wrap background");
assert.ok(
  Math.min(swSlot.w, swSlot.h) < 50 && Math.max(swSlot.w, swSlot.h) > 20,
  "slot is the clear opening through the bar, not the outer bay"
);

const sePiece = demoLid.pieces.find((p) => p.label === "SE");
const seHole = featureShapes(sePiece).find((s) => s.kind === "hole");
const seOpen = openingFills(sePiece).find((s) => s.kind === "circle");
assert.ok(seHole && seOpen, "cord hole inner Ø fill");
assert.equal(seOpen.r, seHole.inner_r, "background circle matches inner radius");
assert.ok(!openingFills(sePiece).some((s) => s.kind === "circle" && s.r === seHole.outer_r));

assert.equal(feedingBay(70), 70 + 2 * SPLINE_W, "feeding bay = opening + 2×spline");
assert.equal(featureMode(applyFeatureMode(emptyFeat(), "feeding_door")), "feeding_door");
assert.match(featSummary(demo.sides[0][1]), /Feeding door/);
assert.match(scad, /rim_feat\([\s\S]*feeding = true/);
assert.ok(parts.some((p) => p.kind === "edge" && p.feeding_door));

const fatFeed = applyFeatureMode(emptyFeat(), "feeding_door");
fatFeed.feeding_opening = 180;
const fatFeedCorners = [fatFeed, emptyFeat(), emptyFeat(), emptyFeat()];
const fatFeedLid = buildLid(
  900,
  600,
  fatFeedCorners,
  syncSideFeats(900, 600, fatFeedCorners, emptySides()),
  "assembled"
);
assert.ok(fatFeedLid.leg > 200, `feeding grows corner leg, got ${fatFeedLid.leg}`);
assert.ok(feedingBay(180) + 4 <= fatFeedLid.leg);

const s2 = demoLid.pieces.find((p) => p.label === "S2");
const feed = featureShapes(s2).find((s) => s.kind === "feeding");
assert.ok(feed && feed.hollow, "south feeding door");
assert.equal(feed.wall, SPLINE_W, "outer and inner rims use inner spline width");
assert.ok(feed.bay > feed.opening, "outer U wider than clear opening");
assert.ok(feed.outer.depth > feed.inner.depth, "outer back wall beyond the cavity");
assert.ok(feed.doorOuter && feed.doorInner, "inner door is a spline rectangle");
const doorPts = feedingDoorFramePoints(feed);
assert.equal(doorPts.length, 8, "inner door is a single 8-point ribbon");
assert.equal(feedingWallPoints(feed).length, 8, "outer feeding U is an 8-point ribbon");

const feedOpens = openingFills(s2);
const feedSlot = feedOpens.find((s) => s.kind === "rect");
assert.ok(feedSlot, "feeding spline gap is wrap background");
assert.ok(
  Math.abs(Math.min(feedSlot.w, feedSlot.h) - SPLINE_W) < 0.01,
  "slot is spline-width only — glass-sit is not broken"
);
assert.ok(
  Math.max(feedSlot.w, feedSlot.h) > 20,
  "slot follows the feeding bay along the piece"
);
const southBar = s2.h;
assert.ok(southBar > SPLINE_W + 1, "south bar still has glass-sit thickness");
assert.ok(
  Math.min(feedSlot.w, feedSlot.h) < southBar - 1,
  "feeding does not punch the full bar like ingress"
);

const arm = s2.arms.a;
const slot = feedingSplineSlot(arm, feed.bay);
assert.ok(
  Math.abs(slot.h - SPLINE_W) < 0.01 || Math.abs(slot.w - SPLINE_W) < 0.01
);
const g = feedingGeometry(arm, 70, 40);
assert.ok(g.hinge.a && g.hinge.b, "hinge along the main rim");

const both = applyFeatureMode(emptyFeat(), "feeding_door");
assert.equal(both.lid_ingress, false, "feeding mode clears ingress");

console.log("ok  rim model + assembled/blowout + BOM checks passed");
