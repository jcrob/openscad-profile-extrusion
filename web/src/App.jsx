import { useEffect, useMemo, useState } from "react";

const emptyEdge = () => ({
  kind: "edge",
  qty: 1,
  length: 120,
  stem_gripper_sides: 0,
  cord_hole: false,
  cord_hole_inner_d: 6,
  cord_hole_pos: "middle",
  cord_under: false,
  cord_under_gap_len: 20,
  lid_ingress: false,
  ingress_depth: 30,
  ingress_length: 40,
  ingress_remove_right_rim: false,
});

const emptyCorner = () => ({
  kind: "corner",
  qty: 1,
});

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

function Field({ label, children, checkbox }) {
  return (
    <label className={`field${checkbox ? " checkbox" : ""}`}>
      {!checkbox && <span>{label}</span>}
      {children}
      {checkbox && <span>{label}</span>}
    </label>
  );
}

function EdgeEditor({ part, onChange, onRemove }) {
  const set = (key, value) => onChange({ ...part, [key]: value });
  return (
    <div className="part-card">
      <div className="head">
        <span className="kind">Edge replica</span>
        <button type="button" className="btn danger" onClick={onRemove}>
          Remove
        </button>
      </div>
      <div className="grid">
        <Field label="Qty">
          <input
            type="number"
            min={1}
            max={20}
            value={part.qty}
            onChange={(e) => set("qty", Number(e.target.value))}
          />
        </Field>
        <Field label="Length (mm)">
          <input
            type="number"
            min={1}
            step={1}
            value={part.length}
            onChange={(e) => set("length", Number(e.target.value))}
          />
        </Field>
        <Field label="Stem grippers">
          <select
            value={part.stem_gripper_sides}
            onChange={(e) => set("stem_gripper_sides", Number(e.target.value))}
          >
            <option value={0}>0 — none</option>
            <option value={1}>1 — start end</option>
            <option value={2}>2 — both ends</option>
            <option value={3}>3 — finish end</option>
          </select>
        </Field>
        <Field label="Cord hole" checkbox>
          <input
            type="checkbox"
            checked={part.cord_hole}
            onChange={(e) => set("cord_hole", e.target.checked)}
          />
        </Field>
        {part.cord_hole && (
          <>
            <Field label="Hole inner Ø (mm)">
              <input
                type="number"
                min={1}
                step={0.5}
                value={part.cord_hole_inner_d}
                onChange={(e) => set("cord_hole_inner_d", Number(e.target.value))}
              />
            </Field>
            <Field label="Hole position">
              <select
                value={part.cord_hole_pos}
                onChange={(e) => set("cord_hole_pos", e.target.value)}
              >
                <option value="left">left</option>
                <option value="middle">middle</option>
                <option value="right">right</option>
              </select>
            </Field>
          </>
        )}
        <Field label="Cord under" checkbox>
          <input
            type="checkbox"
            checked={part.cord_under}
            onChange={(e) => set("cord_under", e.target.checked)}
          />
        </Field>
        {part.cord_under && (
          <Field label="Under gap (mm)">
            <input
              type="number"
              min={1}
              value={part.cord_under_gap_len}
              onChange={(e) => set("cord_under_gap_len", Number(e.target.value))}
            />
          </Field>
        )}
        <Field label="Lid ingress" checkbox>
          <input
            type="checkbox"
            checked={part.lid_ingress}
            onChange={(e) => set("lid_ingress", e.target.checked)}
          />
        </Field>
        {part.lid_ingress && (
          <>
            <Field label="Ingress depth (mm)">
              <input
                type="number"
                min={1}
                value={part.ingress_depth}
                onChange={(e) => set("ingress_depth", Number(e.target.value))}
              />
            </Field>
            <Field label="Ingress length (mm)">
              <input
                type="number"
                min={1}
                value={part.ingress_length}
                onChange={(e) => set("ingress_length", Number(e.target.value))}
              />
            </Field>
            <Field label="Remove right rim" checkbox>
              <input
                type="checkbox"
                checked={part.ingress_remove_right_rim}
                onChange={(e) => set("ingress_remove_right_rim", e.target.checked)}
              />
            </Field>
          </>
        )}
      </div>
    </div>
  );
}

function CornerEditor({ part, onChange, onRemove }) {
  return (
    <div className="part-card">
      <div className="head">
        <span className="kind">Corner assembly</span>
        <button type="button" className="btn danger" onClick={onRemove}>
          Remove
        </button>
      </div>
      <p style={{ color: "var(--muted)", margin: "0 0 0.75rem", fontSize: "0.85rem" }}>
        Prints both pegged halves (fit preview off). One STL per assembly.
      </p>
      <div className="grid">
        <Field label="Qty">
          <input
            type="number"
            min={1}
            max={16}
            value={part.qty}
            onChange={(e) => onChange({ ...part, qty: Number(e.target.value) })}
          />
        </Field>
      </div>
    </div>
  );
}

export default function App() {
  const [name, setName] = useState("aquarium-lid-plate");
  const [parts, setParts] = useState([emptyEdge()]);
  const [health, setHealth] = useState(null);
  const [printer, setPrinter] = useState(null);
  const [busy, setBusy] = useState(false);
  const [log, setLog] = useState("Ready.");
  const [job, setJob] = useState(null);

  useEffect(() => {
    api("/api/health").then(setHealth).catch((e) => setLog(String(e)));
    api("/api/printer").then(setPrinter).catch(() => {});
  }, []);

  const bomPreview = useMemo(() => {
    let edges = 0;
    let corners = 0;
    let stls = 0;
    for (const p of parts) {
      if (p.kind === "edge") {
        edges += p.qty;
        stls += p.qty;
      } else {
        corners += p.qty;
        stls += p.qty;
      }
    }
    return { edges, corners, stls };
  }, [parts]);

  const updatePart = (i, next) => {
    setParts((prev) => prev.map((p, idx) => (idx === i ? next : p)));
  };

  const removePart = (i) => {
    setParts((prev) => prev.filter((_, idx) => idx !== i));
  };

  const generate = async () => {
    setBusy(true);
    setLog("Submitting parts list…");
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

  return (
    <div className="app">
      <header className="hero">
        <h1>Aquarium lid → Bambu print</h1>
        <p>
          Build a parts list of edge replicas and corner pieces, auto-arrange on a
          P1S plate with locked print settings, then download or send to your LAN
          printer.
        </p>
      </header>

      <div className="status-bar">
        <span className={`pill ${health?.ok ? "ok" : ""}`}>
          API {health?.ok ? "up" : "…"}
        </span>
        <span className={`pill ${health?.orca ? "ok" : "warn"}`}>
          OrcaSlicer {health?.orca ? "found" : "missing (STL zip fallback)"}
        </span>
        <span className={`pill ${printer?.configured ? "ok" : "warn"}`}>
          Printer {printer?.configured ? `${printer.ip}` : "not configured"}
        </span>
      </div>

      <section className="panel">
        <h2>Job name</h2>
        <div className="name-row">
          <input value={name} onChange={(e) => setName(e.target.value)} />
        </div>

        <h2>Parts list</h2>
        <div className="row-actions">
          <button type="button" className="btn" onClick={() => setParts((p) => [...p, emptyEdge()])}>
            Add edge
          </button>
          <button
            type="button"
            className="btn"
            onClick={() => setParts((p) => [...p, emptyCorner()])}
          >
            Add corner
          </button>
        </div>

        {parts.map((part, i) =>
          part.kind === "edge" ? (
            <EdgeEditor
              key={i}
              part={part}
              onChange={(next) => updatePart(i, next)}
              onRemove={() => removePart(i)}
            />
          ) : (
            <CornerEditor
              key={i}
              part={part}
              onChange={(next) => updatePart(i, next)}
              onRemove={() => removePart(i)}
            />
          )
        )}
      </section>

      <section className="panel">
        <h2>BOM preview</h2>
        <div className="bom">
          <div className="stat">
            <div className="n">{bomPreview.edges}</div>
            <div className="l">Edge pieces</div>
          </div>
          <div className="stat">
            <div className="n">{bomPreview.corners}</div>
            <div className="l">Corner assemblies</div>
          </div>
          <div className="stat">
            <div className="n">{bomPreview.stls}</div>
            <div className="l">STL files</div>
          </div>
          {job?.bom && (
            <div className="stat">
              <div className="n">{Math.round((job.bom.plate_fill_ratio || 0) * 100)}%</div>
              <div className="l">Est. plate fill</div>
            </div>
          )}
        </div>

        <div className="actions-footer">
          <button type="button" className="btn primary" disabled={busy || !parts.length} onClick={generate}>
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
      </section>

      <section className="panel">
        <h2>Status</h2>
        <div className="job-box">{log}</div>
      </section>
    </div>
  );
}
