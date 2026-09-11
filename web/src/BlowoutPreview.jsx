import { useMemo, useState } from "react";
import {
  alignmentGuides,
  blowoutGapSize,
  blowoutPieces,
  sideOffset,
  cornerOffset,
  sideSegments,
} from "./blowoutLayout.js";

export default function BlowoutPreview() {
  const [gw, setGw] = useState(600);
  const [gd, setGd] = useState(450);

  const layout = useMemo(() => {
    const gap = blowoutGapSize();
    const { pieces, leg, W } = blowoutPieces(gw, gd, gap);
    const guides = alignmentGuides(gw, gd, gap);
    const sw = cornerOffset(0, gap, gw, gd);
    const se = cornerOffset(1, gap, gw, gd);
    const south = sideOffset(0, gap, gw, gd);
    const east = sideOffset(1, gap, gw, gd);
    const ns = sideSegments(0, gw, gd).length;
    const ne = sideSegments(1, gw, gd).length;
    return { pieces, gap, leg, W, guides, sw, se, south, east, ns, ne };
  }, [gw, gd]);

  const { pieces, gap, leg, guides, sw, se, south, east, ns, ne } = layout;
  const pad = 80;
  const minX = Math.min(0, ...pieces.map((p) => p.x)) - pad;
  const minZ = Math.min(0, ...pieces.map((p) => p.z)) - pad;
  const maxX = Math.max(gw, ...pieces.map((p) => p.x + p.w)) + pad;
  const maxZ = Math.max(gd, ...pieces.map((p) => p.z + p.h)) + pad;
  const vbW = maxX - minX;
  const vbH = maxZ - minZ;
  // SVG Y grows down; world Z grows up.
  const ty = (z) => maxZ - z;

  const southAligned = sw[1] === south[1] && se[1] === south[1];
  const eastAligned = se[0] === east[0];

  return (
    <section className="panel blowout-panel">
      <h2>Lid blowout layout</h2>
      <p className="blowout-copy">
        Exploded XZ inspection: NW stays at (−gap, +gap). Far X is
        gap × (south segments + 1), far Z is gap × (east segments + 1).
        Each side copies its start corner.
      </p>
      <div className="grid blowout-controls">
        <label className="field">
          <span>Glass width (mm)</span>
          <input
            type="number"
            min={200}
            max={2000}
            value={gw}
            onChange={(e) => setGw(Number(e.target.value) || 0)}
          />
        </label>
        <label className="field">
          <span>Glass depth (mm)</span>
          <input
            type="number"
            min={200}
            max={2000}
            value={gd}
            onChange={(e) => setGd(Number(e.target.value) || 0)}
          />
        </label>
        <div className="stat blowout-stat">
          <div className="n">{gap.toFixed(1)} mm</div>
          <div className="l">Shared blowout gap</div>
        </div>
        <div className="stat blowout-stat">
          <div className="n">{leg.toFixed(0)} mm</div>
          <div className="l">Corner leg</div>
        </div>
      </div>

      <div className="blowout-svg-wrap">
        <svg
          viewBox={`${minX} ${minZ} ${vbW} ${vbH}`}
          role="img"
          aria-label="Blowout lid pieces aligned on shared rows and columns"
        >
          <rect
            className="glass"
            x={0}
            y={ty(gd)}
            width={gw}
            height={gd}
          />
          <text className="glass-label" x={gw / 2} y={ty(gd / 2)}>
            glass {gw}×{gd}
          </text>

          <line
            className="guide south"
            x1={minX}
            y1={ty(guides.southZ)}
            x2={maxX}
            y2={ty(guides.southZ)}
          />
          <line
            className="guide north"
            x1={minX}
            y1={ty(guides.northZ)}
            x2={maxX}
            y2={ty(guides.northZ)}
          />
          <line
            className="guide east"
            x1={guides.eastX}
            y1={minZ}
            x2={guides.eastX}
            y2={maxZ}
          />
          <line
            className="guide west"
            x1={guides.westX}
            y1={minZ}
            x2={guides.westX}
            y2={maxZ}
          />
          <text className="guide-label" x={minX + 8} y={ty(guides.southZ) - 6}>
            south Z = −gap×({ne}+1)
          </text>
          <text className="guide-label" x={minX + 8} y={ty(guides.northZ) + 14}>
            north Z = +gap (NW fixed)
          </text>
          <text className="guide-label" x={guides.westX + 8} y={ty(gd / 2)}>
            west X = −gap (NW fixed)
          </text>
          <text className="guide-label" x={guides.eastX + 8} y={ty(gd / 2)}>
            east X = +gap×({ns}+1)
          </text>

          {pieces.map((p, i) => (
            <rect
              key={`${p.label}-${p.kind}-${i}`}
              className={p.kind.startsWith("corner") ? "piece corner" : "piece straight"}
              x={p.x}
              y={ty(p.z + p.h)}
              width={p.w}
              height={p.h}
            />
          ))}
        </svg>
      </div>

      <p className={`align-note ${southAligned && eastAligned ? "ok" : "bad"}`}>
        {southAligned && eastAligned
          ? `NW fixed; far X ${east[0].toFixed(1)} = gap×(${ns}+1); far Z ${(-south[1]).toFixed(1)} = gap×(${ne}+1).`
          : `Misaligned: SW Z ${sw[1]} vs south ${south[1]}; SE X ${se[0]} vs east ${east[0]}.`}
      </p>
    </section>
  );
}
