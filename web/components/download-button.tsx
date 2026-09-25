"use client";

import { useEffect, useId, useRef, useState } from "react";

export function DownloadButton({ emphasis = false }: { emphasis?: boolean }) {
  const [available, setAvailable] = useState<boolean | null>(null);
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLSpanElement>(null);
  const popoverId = useId();
  const className = emphasis ? "primary lg" : "primary";

  useEffect(() => {
    let cancelled = false;
    fetch("/api/download")
      .then((response) => response.json())
      .then((body: { available?: boolean }) => {
        if (!cancelled) setAvailable(Boolean(body.available));
      })
      .catch(() => {
        if (!cancelled) setAvailable(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!open) return;
    function onKey(event: KeyboardEvent) {
      if (event.key === "Escape") setOpen(false);
    }
    function onPointer(event: PointerEvent) {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    }
    window.addEventListener("keydown", onKey);
    window.addEventListener("pointerdown", onPointer);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("pointerdown", onPointer);
    };
  }, [open]);

  if (available) {
    return (
      <a className={className} href="/download">
        Download for Mac
      </a>
    );
  }

  return (
    <span className="download" ref={rootRef}>
      <button
        className={className}
        type="button"
        aria-expanded={open}
        aria-controls={popoverId}
        onClick={() => {
          if (available === false) setOpen((value) => !value);
        }}
      >
        Download for Mac
      </button>
      {open ? (
        <span className="popover" id={popoverId} role="status">
          The signed Mac build is not up for download yet.
        </span>
      ) : null}
    </span>
  );
}
