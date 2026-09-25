"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { currentDesk, workspaces, type DemoWorkspace } from "@/lib/demo-data";

const STAGE_AR = 2.25;

export function StageDemo() {
  const [items, setItems] = useState<DemoWorkspace[]>(workspaces);
  const [selected, setSelected] = useState(workspaces[0].id);
  const [pose, setPose] = useState<"arranged" | "scattered">("arranged");
  const [animate, setAnimate] = useState(true);
  const [report, setReport] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [name, setName] = useState("");
  const [highlight, setHighlight] = useState<string | null>(null);
  const [narrow, setNarrow] = useState(false);
  const timers = useRef<number[]>([]);
  const workspace = items.find((item) => item.id === selected) ?? items[0];
  const bounds = useMemo(() => union(workspace), [workspace]);
  const fit = useMemo(() => fitBox(bounds.w / bounds.h), [bounds]);
  const active = workspace.apps.find((app) => app.name === highlight);

  useEffect(() => {
    const query = window.matchMedia("(max-width: 720px)");
    const apply = () => setNarrow(query.matches);
    apply();
    query.addEventListener("change", apply);
    return () => query.removeEventListener("change", apply);
  }, []);

  useEffect(() => {
    function onClick(event: MouseEvent) {
      const link = (event.target as Element | null)?.closest?.("a[href='#demo']");
      if (!link) return;
      play(workspace);
    }
    document.addEventListener("click", onClick);
    return () => document.removeEventListener("click", onClick);
  });

  useEffect(() => {
    const pending = timers.current;
    return () => pending.forEach((id) => window.clearTimeout(id));
  }, []);

  function later(fn: () => void, ms: number) {
    const id = window.setTimeout(fn, ms);
    timers.current.push(id);
  }

  function play(next: DemoWorkspace) {
    timers.current.forEach((id) => window.clearTimeout(id));
    timers.current = [];
    setReport(null);
    setHighlight(null);
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced) {
      setAnimate(false);
      setPose("arranged");
      setReport(summary(next));
      return;
    }
    setAnimate(false);
    setPose("scattered");
    later(() => {
      setAnimate(true);
      setPose("arranged");
      later(() => setReport(summary(next)), 760);
    }, 520);
  }

  function select(id: string) {
    const next = items.find((item) => item.id === id);
    if (!next || next.id === workspace.id) return;
    setSelected(id);
    play(next);
  }

  function scatter() {
    timers.current.forEach((id) => window.clearTimeout(id));
    timers.current = [];
    setReport(null);
    setAnimate(true);
    setPose("scattered");
  }

  function save() {
    const trimmed = name.trim();
    if (!trimmed) return;
    const next = { ...currentDesk, id: `saved-${Date.now()}`, name: trimmed };
    setItems((current) => [next, ...current]);
    setSelected(next.id);
    setName("");
    setSaving(false);
    play(next);
  }

  const status = report ?? (pose === "scattered" ? "Out of place." : "Saved arrangement.");

  return (
    <div className="shell" aria-label="Interactive Stage preview">
      <div className="desk-bar">
        <div className="chips" role="tablist" aria-label="Workspaces">
          {items.map((item) => (
            <button
              key={item.id}
              type="button"
              role="tab"
              aria-selected={item.id === workspace.id}
              className={item.id === workspace.id ? "chip on" : "chip"}
              onClick={() => select(item.id)}
            >
              {item.name}
            </button>
          ))}
        </div>
        <div className="desk-actions">
          {saving ? (
            <>
              <input
                aria-label="Workspace name"
                placeholder="Name this desk"
                value={name}
                onChange={(event) => setName(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter") save();
                  if (event.key === "Escape") setSaving(false);
                }}
              />
              <button className="primary" type="button" onClick={save}>
                Save
              </button>
              <button className="quiet" type="button" onClick={() => setSaving(false)}>
                Cancel
              </button>
            </>
          ) : (
            <>
              <button className="quiet" type="button" onClick={() => setSaving(true)}>
                Save workspace
              </button>
              <button className="quiet" type="button" onClick={scatter}>
                Scatter
              </button>
              <button className="primary" type="button" onClick={() => play(workspace)}>
                Restore
              </button>
            </>
          )}
        </div>
      </div>

      <div className={`${narrow ? "stack" : "stage"}${animate ? " motion" : ""}`} style={narrow ? undefined : { aspectRatio: `${STAGE_AR}` }}>
        {narrow ? (
          workspace.displays.map((display) => (
            <DisplayGlass key={display.id} display={display} pose={pose} highlight={highlight} stacked />
          ))
        ) : (
          <div className={`fit${animate ? " motion" : ""}`} style={fit}>
            {workspace.displays.map((display) => (
              <DisplayGlass key={display.id} display={display} pose={pose} highlight={highlight} bounds={bounds} />
            ))}
          </div>
        )}
      </div>

      <div className="legend">
        {workspace.apps.map((app) => (
          <button
            key={app.name}
            type="button"
            className={highlight === app.name ? "on" : ""}
            onMouseEnter={() => setHighlight(app.name)}
            onMouseLeave={() => setHighlight(null)}
            onFocus={() => setHighlight(app.name)}
            onBlur={() => setHighlight(null)}
          >
            <span className={`badge ${app.fidelity}`}>{app.fidelity}</span>
            {app.name}
          </button>
        ))}
      </div>
      <p className="status" aria-live="polite">
        {active ? active.note : status}
      </p>
    </div>
  );
}

function DisplayGlass({
  display,
  pose,
  highlight,
  bounds,
  stacked = false,
}: {
  display: DemoWorkspace["displays"][number];
  pose: "arranged" | "scattered";
  highlight: string | null;
  bounds?: { x: number; y: number; w: number; h: number };
  stacked?: boolean;
}) {
  const frame = bounds ? box(display, bounds) : undefined;
  return (
    <div
      className="display"
      style={
        stacked
          ? { aspectRatio: `${display.w} / ${display.h}` }
          : frame
      }
    >
      <header>{display.name}</header>
      <div className="glass">
        {display.windows.map((window) => {
          const placed = pose === "scattered" ? mess(window.id) : box(window, display);
          const dim = highlight && highlight !== window.app;
          return (
            <div
              key={window.id}
              className={`tile${highlight === window.app ? " hot" : ""}${dim ? " dim" : ""}`}
              style={{ ...placed, background: window.tone }}
            >
              <span className="dots" aria-hidden="true">
                <i />
                <i />
                <i />
              </span>
              <strong>{window.app}</strong>
              <span>{window.title}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function summary(workspace: DemoWorkspace) {
  const partial = workspace.apps.filter((app) => app.fidelity === "Partial").map((app) => app.name);
  const missing = workspace.apps.filter((app) => app.fidelity === "Unsupported").map((app) => app.name);
  const bits = [`${workspace.name} is back.`];
  if (partial.length) bits.push(`${join(partial)} came back as layout only.`);
  if (missing.length) bits.push(`${join(missing)} could not be restored.`);
  return bits.join(" ");
}

function join(names: string[]) {
  if (names.length <= 1) return names[0] ?? "";
  return `${names.slice(0, -1).join(", ")} and ${names[names.length - 1]}`;
}

function union(workspace: DemoWorkspace) {
  const displays = workspace.displays;
  const minX = Math.min(...displays.map((display) => display.x));
  const minY = Math.min(...displays.map((display) => display.y));
  const maxX = Math.max(...displays.map((display) => display.x + display.w));
  const maxY = Math.max(...displays.map((display) => display.y + display.h));
  return { x: minX, y: minY, w: maxX - minX, h: maxY - minY };
}

function fitBox(deskAR: number) {
  if (deskAR >= STAGE_AR) {
    const width = 94;
    return { width: `${width}%`, height: `${width * (STAGE_AR / deskAR)}%` };
  }
  const height = 90;
  return { width: `${height * (deskAR / STAGE_AR)}%`, height: `${height}%` };
}

function mess(id: string) {
  let hash = 2166136261;
  for (let index = 0; index < id.length; index += 1) {
    hash ^= id.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  const value = Math.abs(hash);
  return {
    left: `${6 + (value % 46)}%`,
    top: `${8 + ((value >> 4) % 44)}%`,
    width: `${30 + ((value >> 8) % 16)}%`,
    height: `${24 + ((value >> 12) % 14)}%`,
  };
}

function box(
  frame: { x: number; y: number; w: number; h: number },
  bounds: { x: number; y: number; w: number; h: number },
) {
  return {
    left: `${((frame.x - bounds.x) / bounds.w) * 100}%`,
    top: `${((frame.y - bounds.y) / bounds.h) * 100}%`,
    width: `${(frame.w / bounds.w) * 100}%`,
    height: `${(frame.h / bounds.h) * 100}%`,
  };
}
