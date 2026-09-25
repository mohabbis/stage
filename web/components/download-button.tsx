"use client";

import { useEffect, useState } from "react";

export function DownloadButton() {
  const [available, setAvailable] = useState<boolean | null>(null);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    fetch("/api/download")
      .then((response) => response.json())
      .then((body: { available?: boolean }) => setAvailable(Boolean(body.available)))
      .catch(() => setAvailable(false));
  }, []);

  if (available) {
    return <a className="primary" href="/download">Download for Mac</a>;
  }

  return (
    <span>
      <button className="primary" onClick={() => setOpen(true)}>Download for Mac</button>
      {open ? <p className="note">The notarized build is not linked on this deployment yet.</p> : null}
    </span>
  );
}
