"use client";

import { useMemo, useState } from "react";
import { currentDesk, workspaces, type DemoWorkspace } from "@/lib/demo-data";

export function StageDemo() {
  const [items, setItems] = useState<DemoWorkspace[]>(workspaces);
  const [selected, setSelected] = useState(workspaces[0].id);
  const [scattered, setScattered] = useState(false);
  const [report, setReport] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [name, setName] = useState("");
  const workspace = items.find((item) => item.id === selected) ?? items[0];
  const bounds = useMemo(() => union(workspace), [workspace]);

  function restore() {
    setReport(null);
    setScattered(true);
    window.setTimeout(() => setScattered(false), 40);
    window.setTimeout(() => {
      setReport(`Restored ${workspace.name}. Other apps would be hidden, not quit.`);
    }, 800);
  }

  function save() {
    const trimmed = name.trim();
    if (!trimmed) return;
    const next = { ...currentDesk, id: `saved-${Date.now()}`, name: trimmed };
    setItems((current) => [next, ...current]);
    setSelected(next.id);
    setName("");
    setSaving(false);
  }

  return (
    <div className="demo" aria-label="Interactive Stage preview">
      <header>
        <span className="dot" />
        <span className="dot" />
        <span className="dot" />
        <strong style={{ marginLeft: 8 }}>Stage</strong>
        <span className="note" style={{ margin: 0 }}>Browser preview of the Mac app</span>
      </header>
      <aside className="side">
        {items.map((item) => (
          <button key={item.id} className={item.id === workspace.id ? "active" : ""} onClick={() => { setSelected(item.id); setReport(null); }}>
            {item.name}
          </button>
        ))}
      </aside>
      <div>
        <div className="canvas">
          <div className="stage">
            {workspace.displays.map((display) => {
              const style = box(display, bounds);
              return (
                <div key={display.id} className="display" style={style}>
                  {display.windows.map((window) => {
                    const placed = box(window, { x: display.x, y: display.y, w: display.w, h: display.h });
                    const jitter = scattered ? { left: `${8 + (window.x % 17)}%`, top: `${12 + (window.y % 23)}%`, width: "28%", height: "24%" } : placed;
                    return (
                      <div key={window.id} className="tile" style={{ ...jitter, background: window.tone }}>
                        <strong>{window.app}</strong>
                        <span>{window.title}</span>
                      </div>
                    );
                  })}
                </div>
              );
            })}
          </div>
        </div>
        <div className="savebar">
          {saving ? (
            <>
              <input aria-label="Workspace name" placeholder="ECON 402" value={name} onChange={(event) => setName(event.target.value)} />
              <button className="primary" onClick={save}>Save</button>
            </>
          ) : (
            <>
              <button className="quiet" onClick={() => setSaving(true)}>Save workspace</button>
              <button className="primary" onClick={restore}>Restore</button>
            </>
          )}
        </div>
        {report ? <p className="limits" style={{ padding: "0 16px 16px" }}>{report}</p> : null}
      </div>
      <aside className="inspector">
        <span className={`badge ${workspace.fidelity}`}>{workspace.fidelity}</span>
        {workspace.apps.map((app) => (
          <div className="app" key={app.name}>
            <strong>{app.name}</strong> <span className={`badge ${app.fidelity}`}>{app.fidelity}</span>
            <p>{app.note}</p>
            {app.details.map((detail) => <div key={detail}>{detail}</div>)}
          </div>
        ))}
        <p className="limits">Only the current Space is captured. Stage does not invent state macOS will not give up.</p>
      </aside>
    </div>
  );
}

function union(workspace: DemoWorkspace) {
  const displays = workspace.displays;
  const minX = Math.min(...displays.map((d) => d.x));
  const minY = Math.min(...displays.map((d) => d.y));
  const maxX = Math.max(...displays.map((d) => d.x + d.w));
  const maxY = Math.max(...displays.map((d) => d.y + d.h));
  return { x: minX, y: minY, w: maxX - minX, h: maxY - minY };
}

function box(frame: { x: number; y: number; w: number; h: number }, bounds: { x: number; y: number; w: number; h: number }) {
  return {
    left: `${((frame.x - bounds.x) / bounds.w) * 100}%`,
    top: `${((frame.y - bounds.y) / bounds.h) * 100}%`,
    width: `${(frame.w / bounds.w) * 100}%`,
    height: `${(frame.h / bounds.h) * 100}%`,
  };
}
