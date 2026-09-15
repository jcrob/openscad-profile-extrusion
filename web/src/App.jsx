import { useEffect, useMemo, useState } from "react";
import RimBuilder from "./RimBuilder.jsx";
import {
  bomCsv,
  bomLines,
  bomTotals,
  buildLid,
  demoFeatures,
  emptyCorners,
  emptyFeat,
  emptySides,
  rimScadSource,
  syncSideFeats,
  toPrintParts,
} from "./rimModel.js";

async function api(path, opts = {}) {
  const res = await fetch(path, {
    headers: { "Content-Type": "application/json", ...(opts.headers || {}) },
    ...opts,
  });
  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { detail: text };
  }
  if (!res.ok) {
    const detail = data.detail;
    const msg =
      typeof detail === "string"
        ? detail
        : Array.isArray(detail)
          ? detail.map((d) => d.msg || JSON.stringify(d)).join("; ")
          : res.statusText;
    throw new Error(msg || "Request failed");
  }
  return data;
}

function downloadText(filename, text, mime = "text/plain") {
  const blob = new Blob([text], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export default function App() {
  const [name, setName] = useState("aquarium-lid");
  const [gw, setGw] = useState(900);
  const [gd, setGd] = useState(600);
  const [layout, setLayout] = useState("blowout");
  const [corners, setCorners] = useState(emptyCorners);
  const [sides, setSides] = useState(() => syncSideFeats(900, 600, emptyCorners(), emptySides()));
  const [selectedId, setSelectedId] = useState("corner-0");
  const [health, setHealth] = useState(null);
  const [printer, setPrinter] = useState(null);
  const [busy, setBusy] = useState(false);
  const [log, setLog] = useState("Ready. Build the rim, then generate a plate from the BOM.");
  const [job, setJob] = useState(null);

  useEffect(() => {
    api("/api/health").then(setHealth).catch((e) => setLog(String(e)));
    api("/api/printer").then(setPrinter).catch(() => {});
  }, []);

  const applyGlass = (nextGw, nextGd, nextCorners = corners) => {
    setGw(nextGw);
    setGd(nextGd);
    setCorners(nextCorners);
    setSides((prev) => syncSideFeats(nextGw, nextGd, nextCorners, prev));
  };

  const lid = useMemo(
    () => buildLid(gw, gd, corners, sides, layout),
    [gw, gd, corners, sides, layout]
  );
  const lines = useMemo(() => bomLines(lid.pieces), [lid.pieces]);
  const totals = useMemo(() => bomTotals(lines), [lines]);
  const parts = useMemo(() => toPrintParts(lines), [lines]);

  const onFeatChange = (piece, feat) => {
    if (piece.kind === "corner") {
      const next = corners.map((c, i) => (i === piece.cornerIdx ? feat : c));
      setCorners(next);
      setSides((prev) => syncSideFeats(gw, gd, next, prev));
      return;
    }
    setSides((prev) =>
      prev.map((row, si) =>
        si === piece.sideIdx ? row.map((f, i) => (i === piece.segIdx ? feat : f)) : row
      )
    );
  };

  const loadDemo = () => {
    const demo = demoFeatures();
    applyGlass(demo.gw, demo.gd, demo.corners);
    setSides(syncSideFeats(demo.gw, demo.gd, demo.corners, demo.sides));
    setSelectedId("corner-0");
    setLog("Loaded 900×600 featured demo (one option per corner and side).");
  };

  const clearFeatures = () => {
    const next = emptyCorners();
    setCorners(next);
    setSides((prev) => prev.map((row) => row.map(() => emptyFeat())));
    setLog("Cleared piece features. Segment lengths are unchanged.");
  };

  const generate = async () => {
    setBusy(true);
    setLog("Submitting rim BOM…");
    setJob(null);
    try {
      const result = await api("/api/jobs", {
        method: "POST",
        body: JSON.stringify({ name, parts }),
      });
      setJob(result);
      setLog(`${result.status}: ${result.message}`);
    } catch (e) {
      setLog(`Error: ${e.message}`);
    } finally {
      setBusy(false);
    }
  };

  const sendPrint = async () => {
    if (!job?.job_id) return;
    setBusy(true);
    setLog("Sending to Bambu printer…");
    try {
      const result = await api(`/api/jobs/${job.job_id}/print`, {
        method: "POST",
        body: JSON.stringify({ job_id: job.job_id }),
      });
      setLog(result.message || "Sent.");
      setJob((j) => (j ? { ...j, status: "sent", message: result.message } : j));
    } catch (e) {
      setLog(`Print error: ${e.message}`);
    } finally {
      setBusy(false);
    }
  };

  const downloadScad = () => {
    downloadText(
      `${name || "aquarium-lid"}.scad`,
      rimScadSource({ gw, gd, layout, corners, sides }),
      "text/plain"
    );
    setLog("Downloaded OpenSCAD lid file. Include path must see rim_rectangular_lid.scad.");
  };

  const downloadBom = () => {
    downloadText(`${name || "aquarium-lid"}-bom.csv`, bomCsv(lines), "text/csv");
    setLog("Downloaded BOM CSV.");
  };

  return (
    <div className="app">
      <header className="hero">
        <h1>Aquarium lid builder</h1>
        <p>
          Size the glass, drop features onto each rim piece, and read the
          auto-generated bill of materials. Preview the frame assembled or
          blown out, then download OpenSCAD or send straights to a LAN Bambu
          printer.
        </p>
      </header>

      <div className="status-bar">
        <span className={`pill ${health?.ok ? "ok" : ""}`}>
          API {health?.ok ? "up" : "offline (preview still works)"}
        </span>
        <span className={`pill ${health?.orca ? "ok" : "warn"}`}>
          OrcaSlicer {health?.orca ? "found" : "missing (STL zip fallback)"}
        </span>
        <span className={`pill ${printer?.configured ? "ok" : "warn"}`}>
          Printer {printer?.configured ? `${printer.ip}` : "not configured"}
        </span>
      </div>

      <RimBuilder
        gw={gw}
        gd={gd}
        layout={layout}
        corners={corners}
        sides={sides}
        selectedId={selectedId}
        onGw={(v) => applyGlass(v, gd)}
        onGd={(v) => applyGlass(gw, v)}
        onLayout={setLayout}
        onSelect={setSelectedId}
        onFeatChange={onFeatChange}
        onLoadDemo={loadDemo}
        onClearFeatures={clearFeatures}
      />

      <section className="panel">
        <h2>Bill of materials</h2>
        <p className="blowout-copy">
          Pieces come from the glass size and corner-leg plan. Identical
          straights collapse to one line with quantity. Ingress or a feeding
          door on a corner can lengthen every corner leg.
        </p>
        <div className="bom">
          <div className="stat">
            <div className="n">{totals.corners}</div>
            <div className="l">Corner assemblies</div>
          </div>
          <div className="stat">
            <div className="n">{totals.straights}</div>
            <div className="l">Straight pieces</div>
          </div>
          <div className="stat">
            <div className="n">{totals.featured}</div>
            <div className="l">Featured pieces</div>
          </div>
          <div className="stat">
            <div className="n">{totals.pieces}</div>
            <div className="l">Print items</div>
          </div>
          {job?.bom && (
            <div className="stat">
              <div className="n">{Math.round((job.bom.plate_fill_ratio || 0) * 100)}%</div>
              <div className="l">Est. plate fill</div>
            </div>
          )}
        </div>

        {lines.length === 0 ? (
          <p className="feature-empty">No pieces — increase the glass span.</p>
        ) : (
          <div className="bom-table-wrap">
            <table className="bom-table">
              <thead>
                <tr>
                  <th>Piece</th>
                  <th>Type</th>
                  <th>Qty</th>
                  <th>Length</th>
                  <th>End joins</th>
                  <th>Features</th>
                </tr>
              </thead>
              <tbody>
                {lines.map((row) => (
                  <tr key={row.key}>
                    <td>{row.piece}</td>
                    <td>{row.name}</td>
                    <td>{row.qty}</td>
                    <td>
                      {row.kind === "corner"
                        ? `${row.length.toFixed(0)} × ${row.lengthB.toFixed(0)} mm`
                        : `${row.length.toFixed(0)} mm`}
                    </td>
                    <td>{row.joins}</td>
                    <td>{row.features}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <div className="name-row" style={{ marginTop: "1rem" }}>
          <label className="field">
            <span>Job name</span>
            <input value={name} onChange={(e) => setName(e.target.value)} />
          </label>
        </div>

        <div className="actions-footer">
          <button type="button" className="btn" onClick={downloadBom} disabled={!lines.length}>
            Download BOM CSV
          </button>
          <button type="button" className="btn" onClick={downloadScad} disabled={!lines.length}>
            Download OpenSCAD
          </button>
          <button
            type="button"
            className="btn primary"
            disabled={busy || !parts.length}
            onClick={generate}
          >
            {busy ? "Working…" : "Generate & arrange"}
          </button>
          {job?.download_url && (
            <a className="btn" href={job.download_url}>
              Download {job.gcode_3mf ? ".gcode.3mf" : "STL zip"}
            </a>
          )}
          <button
            type="button"
            className="btn"
            disabled={busy || !job?.gcode_3mf || !printer?.configured}
            onClick={sendPrint}
          >
            Send to printer
          </button>
        </div>
        <p className="feature-hint">
          OpenSCAD download includes corner-arm features. LAN print sends stock
          corner assemblies plus featured straights from this BOM.
        </p>
      </section>

      <section className="panel">
        <h2>Status</h2>
        <div className="job-box">{log}</div>
      </section>
    </div>
  );
}
