import { useMemo } from "react";
import { alignmentGuides, sideSegments } from "./blowoutLayout.js";
import { piecePath, worldBounds } from "./rimDraw.js";
import {
  CORD_POS_OPTIONS,
  CORNER_ARM_HINT,
  CORNER_NAMES,
  FEATURE_MODES,
  SIDE_NAMES,
  SIDE_SHORT,
  applyFeatureMode,
  buildLid,
  cloneFeat,
  featActive,
  featHasIngress,
  featSummary,
  featureMode,
  ingressBay,
  ingressFits,
  ingressPad,
} from "./rimModel.js";

function Field({ label, children, checkbox }) {
  return (
    <label className={`field${checkbox ? " checkbox" : ""}`}>
      {!checkbox && <span>{label}</span>}
      {children}
      {checkbox && <span>{label}</span>}
    </label>
  );
}

function ArmSelect({ value, onChange, cornerIdx }) {
  const hint = CORNER_ARM_HINT[cornerIdx] || { a: "arm A", b: "arm B" };
  return (
    <select value={value} onChange={(e) => onChange(e.target.value)}>
      <option value="a">Arm A — {hint.a}</option>
      <option value="b">Arm B — {hint.b}</option>
    </select>
  );
}

function FeatureEditor({ piece, onChange }) {
  if (!piece) {
    return (
      <div className="feature-empty">
        Select a corner or straight in the preview or the piece list to set
        features.
      </div>
    );
  }

  const f = cloneFeat(piece.feat);
  const set = (patch) => onChange({ ...f, ...patch });
  const mode = featureMode(f);
  const isCorner = piece.kind === "corner";
  const fits = ingressFits(f, piece.length);
  const bay = featHasIngress(f) ? ingressBay(f.ingress_opening) : 0;

  return (
    <div className="feature-editor">
      <div className="feature-head">
        <span className="kind">{piece.label}</span>
        <span className="feature-meta">
          {isCorner
            ? `Corner L · ${piece.length.toFixed(0)} × ${piece.lengthB.toFixed(0)} mm · ${piece.joins}`
            : `Straight · ${piece.length.toFixed(0)} mm · ${piece.joins}`}
        </span>
      </div>

      <div className="grid">
        <Field label="Feature">
          <select
            value={mode}
            onChange={(e) => onChange(applyFeatureMode(f, e.target.value))}
          >
            {FEATURE_MODES.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </Field>
      </div>

      {mode === "combine" && (
        <div className="grid feature-toggles">
          <Field label="Cord hole" checkbox>
            <input
              type="checkbox"
              checked={f.cord_hole}
              onChange={(e) => set({ cord_hole: e.target.checked })}
            />
          </Field>
          <Field label="Cord under" checkbox>
            <input
              type="checkbox"
              checked={f.cord_under}
              onChange={(e) => set({ cord_under: e.target.checked })}
            />
          </Field>
          <Field label="Lid ingress" checkbox>
            <input
              type="checkbox"
              checked={f.lid_ingress}
              onChange={(e) => set({ lid_ingress: e.target.checked })}
            />
          </Field>
        </div>
      )}

      {f.cord_hole && (
        <div className="grid">
          <Field label="Hole inner Ø (mm)">
            <input
              type="number"
              min={1}
              step={0.5}
              value={f.cord_hole_inner_d}
              onChange={(e) => set({ cord_hole_inner_d: Number(e.target.value) })}
            />
          </Field>
          <Field label="Hole position">
            <select
              value={f.cord_hole_pos}
              onChange={(e) => set({ cord_hole_pos: e.target.value })}
            >
              {CORD_POS_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </Field>
          {isCorner && (
            <Field label="Hole on arm">
              <ArmSelect
                value={f.cord_hole_on}
                onChange={(cord_hole_on) => set({ cord_hole_on })}
                cornerIdx={piece.cornerIdx}
              />
            </Field>
          )}
        </div>
      )}

      {f.cord_under && (
        <div className="grid">
          <Field label="Under gap (mm)">
            <input
              type="number"
              min={1}
              value={f.cord_under_gap_len}
              onChange={(e) => set({ cord_under_gap_len: Number(e.target.value) })}
            />
          </Field>
          {isCorner && (
            <Field label="Under on arm">
              <ArmSelect
                value={f.cord_under_on}
                onChange={(cord_under_on) => set({ cord_under_on })}
                cornerIdx={piece.cornerIdx}
              />
            </Field>
          )}
        </div>
      )}

      {f.lid_ingress && (
        <div className="grid">
          <Field label="Clear opening (mm)">
            <input
              type="number"
              min={1}
              value={f.ingress_opening}
              onChange={(e) => set({ ingress_opening: Number(e.target.value) })}
            />
          </Field>
          <Field label="Ingress depth (mm)">
            <input
              type="number"
              min={1}
              value={f.ingress_depth}
              onChange={(e) => set({ ingress_depth: Number(e.target.value) })}
            />
          </Field>
          {isCorner && (
            <Field label="Ingress on arm">
              <ArmSelect
                value={f.ingress_on}
                onChange={(ingress_on) => set({ ingress_on })}
                cornerIdx={piece.cornerIdx}
              />
            </Field>
          )}
        </div>
      )}

      {f.lid_ingress && (
        <p className={`align-note ${fits ? "ok" : "bad"}`}>
          {fits
            ? `U bay is opening + ${ingressPad().toFixed(0)} mm pad = ${bay.toFixed(0)} mm.`
            : `Opening ${f.ingress_opening} mm needs a ${bay.toFixed(0)} mm bay; this piece is only ${piece.length.toFixed(0)} mm. Use a longer segment or a smaller opening.`}
        </p>
      )}

      {!featActive(f) && (
        <p className="feature-hint">
          No cutouts on this piece. Joins stay male/female as planned for the
          chain.
        </p>
      )}
    </div>
  );
}

export default function RimBuilder({
  gw,
  gd,
  layout,
  corners,
  sides,
  selectedId,
  onGw,
  onGd,
  onLayout,
  onSelect,
  onFeatChange,
  onLoadDemo,
  onClearFeatures,
}) {
  const lid = useMemo(
    () => buildLid(gw, gd, corners, sides, layout),
    [gw, gd, corners, sides, layout]
  );
  const { pieces, gap, leg } = lid;
  const guides = useMemo(
    () => (layout === "blowout" ? alignmentGuides(gw, gd, gap, leg) : null),
    [layout, gw, gd, gap, leg]
  );
  const ns = sideSegments(0, gw, gd, leg).length;
  const ne = sideSegments(1, gw, gd, leg).length;

  const logical = useMemo(() => {
    const seen = new Map();
    for (const p of pieces) {
      if (!seen.has(p.id)) seen.set(p.id, p);
    }
    return [...seen.values()];
  }, [pieces]);

  const selected = logical.find((p) => p.id === selectedId) || null;

  const frame = useMemo(() => {
    const pad = layout === "blowout" ? 90 : 56;
    return worldBounds(pieces, gw, gd, pad);
  }, [pieces, gw, gd, layout]);
  const { minX, minZ, maxX, maxZ, vbW, vbH, ty, viewBox } = frame;

  const updateSelected = (feat) => {
    if (!selected) return;
    onFeatChange(selected, feat);
  };

  return (
    <section className="panel rim-builder">
      <div className="rim-toolbar">
        <div>
          <h2>Build rim</h2>
          <p className="blowout-copy">
            Set the glass-channel span, then assign cord holes, cord-under
            notches, or lid ingress on each corner and straight. Switch
            assembled and blowout without changing the BOM.
          </p>
        </div>
        <div className="view-toggle" role="group" aria-label="Lid view">
          <button
            type="button"
            className={`btn ${layout === "assembled" ? "primary" : ""}`}
            onClick={() => onLayout("assembled")}
          >
            Assembled
          </button>
          <button
            type="button"
            className={`btn ${layout === "blowout" ? "primary" : ""}`}
            onClick={() => onLayout("blowout")}
          >
            Blowout
          </button>
        </div>
      </div>

      <div className="grid blowout-controls">
        <Field label="Glass width (mm)">
          <input
            type="number"
            min={200}
            max={2000}
            value={gw}
            onChange={(e) => onGw(Number(e.target.value) || 0)}
          />
        </Field>
        <Field label="Glass depth (mm)">
          <input
            type="number"
            min={200}
            max={2000}
            value={gd}
            onChange={(e) => onGd(Number(e.target.value) || 0)}
          />
        </Field>
        <div className="stat blowout-stat">
          <div className="n">{leg.toFixed(0)} mm</div>
          <div className="l">Corner leg</div>
        </div>
        <div className="stat blowout-stat">
          <div className="n">{layout === "blowout" ? `${gap.toFixed(1)} mm` : "0"}</div>
          <div className="l">{layout === "blowout" ? "Blowout gap" : "Assembled"}</div>
        </div>
      </div>

      <div className="row-actions">
        <button type="button" className="btn" onClick={onLoadDemo}>
          Load featured demo
        </button>
        <button type="button" className="btn" onClick={onClearFeatures}>
          Clear features
        </button>
      </div>

      <div className="rim-split">
        <div className={`blowout-svg-wrap ${layout}`}>
          <svg
            viewBox={viewBox}
            preserveAspectRatio="xMidYMid meet"
            role="img"
            aria-label={`${layout} lid with selectable pieces`}
          >
            <rect className="glass" x={0} y={ty(gd)} width={gw} height={gd} />
            <text className="glass-label" x={gw / 2} y={ty(gd / 2)}>
              glass {gw}×{gd}
            </text>

            {layout === "blowout" && guides && (
              <>
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
                  west X = −gap
                </text>
                <text className="guide-label" x={guides.eastX + 8} y={ty(gd / 2)}>
                  east X = +gap×({ns}+1)
                </text>
              </>
            )}

            {pieces.map((p) => {
              const featured = featActive(p.feat);
              const selectedPiece = p.id === selectedId;
              const cls = [
                "piece",
                p.kind === "corner" ? "corner" : "straight",
                featured ? "featured" : "",
                selectedPiece ? "selected" : "",
              ]
                .filter(Boolean)
                .join(" ");
              return (
                <g key={p.id} className="piece-hit" onClick={() => onSelect(p.id)}>
                  <path className={cls} fillRule="evenodd" d={piecePath(p, ty)} />
                </g>
              );
            })}

            {logical.map((p) => (
              <text
                key={`lab-${p.id}`}
                className={`piece-label${p.id === selectedId ? " on" : ""}`}
                x={p.labelX ?? p.x + p.w / 2}
                y={ty(p.labelZ ?? p.z + p.h / 2) + 4}
                onClick={() => onSelect(p.id)}
              >
                {p.label}
              </text>
            ))}
          </svg>
        </div>

        <div className="rim-side">
          <label className="field">
            <span>Piece</span>
            <select
              value={selectedId || ""}
              onChange={(e) => onSelect(e.target.value || null)}
            >
              <option value="">Select a piece…</option>
              <optgroup label="Corners">
                {logical
                  .filter((p) => p.kind === "corner")
                  .map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.label} — {featSummary(p.feat, { corner: true, cornerIdx: p.cornerIdx })}
                    </option>
                  ))}
              </optgroup>
              {[0, 1, 2, 3].map((si) => {
                const segs = logical.filter((p) => p.sideIdx === si);
                if (!segs.length) return null;
                return (
                  <optgroup key={si} label={`${SIDE_NAMES[si]} straights`}>
                    {segs.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.label} ({p.length.toFixed(0)} mm) — {featSummary(p.feat)}
                      </option>
                    ))}
                  </optgroup>
                );
              })}
            </select>
          </label>

          <FeatureEditor piece={selected} onChange={updateSelected} />

          <ul className="piece-legend">
            {CORNER_NAMES.map((name, i) => (
              <li key={name}>
                <button
                  type="button"
                  className={`legend-btn${selectedId === `corner-${i}` ? " on" : ""}`}
                  onClick={() => onSelect(`corner-${i}`)}
                >
                  {name}
                </button>
                <span>{featSummary(corners[i], { corner: true, cornerIdx: i })}</span>
              </li>
            ))}
            {[0, 1, 2, 3].map((si) =>
              (sides[si] || []).map((feat, i) => (
                <li key={`s-${si}-${i}`}>
                  <button
                    type="button"
                    className={`legend-btn${selectedId === `side-${si}-${i}` ? " on" : ""}`}
                    onClick={() => onSelect(`side-${si}-${i}`)}
                  >
                    {SIDE_SHORT[si]}
                    {i + 1}
                  </button>
                  <span>{featSummary(feat)}</span>
                </li>
              ))
            )}
          </ul>
        </div>
      </div>
    </section>
  );
}
