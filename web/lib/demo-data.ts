export type DemoWindow = {
  id: string;
  app: string;
  title: string;
  x: number;
  y: number;
  w: number;
  h: number;
  tone: string;
};

export type DemoDisplay = {
  id: string;
  name: string;
  x: number;
  y: number;
  w: number;
  h: number;
  windows: DemoWindow[];
};

export type DemoApp = {
  name: string;
  fidelity: "Full" | "Partial" | "Unsupported";
  note: string;
  details: string[];
};

export type DemoWorkspace = {
  id: string;
  name: string;
  fidelity: "Full" | "Partial";
  displays: DemoDisplay[];
  apps: DemoApp[];
};

export const workspaces: DemoWorkspace[] = [
  {
    id: "econ",
    name: "ECON 402",
    fidelity: "Full",
    displays: [
      {
        id: "d1",
        name: "Display 1",
        x: 0,
        y: 0,
        w: 1600,
        h: 1000,
        windows: [
          { id: "safari", app: "Safari", title: "Canvas", x: 0, y: 0, w: 960, h: 1000, tone: "#24586f" },
          { id: "preview", app: "Preview", title: "lecture-slides.pdf", x: 960, y: 0, w: 640, h: 1000, tone: "#6d4a32" },
        ],
      },
      {
        id: "d2",
        name: "Display 2",
        x: 1680,
        y: 40,
        w: 1440,
        h: 900,
        windows: [
          { id: "notes", app: "Notes", title: "Lecture notes", x: 1696, y: 56, w: 680, h: 400, tone: "#8a7344" },
          { id: "spotify", app: "Spotify", title: "Focus", x: 2420, y: 56, w: 680, h: 400, tone: "#1d6b45" },
          { id: "terminal", app: "Terminal", title: "~/Documents/econ402", x: 1696, y: 490, w: 1408, h: 430, tone: "#1c2420" },
        ],
      },
    ],
    apps: [
      { name: "Safari", fidelity: "Full", note: "Window layout and tabs.", details: ["Canvas", "FRED", "Google Docs", "Left 60%"] },
      { name: "Preview", fidelity: "Full", note: "Window layout and open documents.", details: ["lecture-slides.pdf", "Right 40%"] },
      { name: "Terminal", fidelity: "Full", note: "Window layout and working directories.", details: ["~/Documents/econ402", "Full width · lower"] },
      { name: "Notes", fidelity: "Partial", note: "Window layout. The open note is not restorable.", details: ["Upper left"] },
      { name: "Spotify", fidelity: "Full", note: "Window layout.", details: ["Upper right"] },
    ],
  },
  {
    id: "writing",
    name: "Writing",
    fidelity: "Partial",
    displays: [
      {
        id: "w1",
        name: "Display 1",
        x: 0,
        y: 0,
        w: 1600,
        h: 1000,
        windows: [
          { id: "pages", app: "Pages", title: "Draft", x: 40, y: 40, w: 980, h: 920, tone: "#3d4a62" },
          { id: "finder", app: "Finder", title: "Research", x: 1060, y: 80, w: 500, h: 640, tone: "#3a4550" },
        ],
      },
    ],
    apps: [
      { name: "Pages", fidelity: "Partial", note: "Window layout. The document path is restored when Preview or TextEdit exposes it.", details: ["Draft"] },
      { name: "Finder", fidelity: "Full", note: "Window layout and open folders.", details: ["~/Documents/Research"] },
    ],
  },
];

export const currentDesk: DemoWorkspace = {
  id: "now",
  name: "Right now",
  fidelity: "Partial",
  displays: [
    {
      id: "n1",
      name: "Display 1",
      x: 0,
      y: 0,
      w: 1600,
      h: 1000,
      windows: [
        { id: "mail", app: "Mail", title: "Inbox", x: 80, y: 120, w: 700, h: 760, tone: "#31485f" },
        { id: "code", app: "Cursor", title: "stage", x: 860, y: 80, w: 680, h: 820, tone: "#2a2a28" },
      ],
    },
  ],
  apps: [
    { name: "Mail", fidelity: "Full", note: "Window layout.", details: ["Inbox"] },
    { name: "Cursor", fidelity: "Partial", note: "Project folder. Unsaved editor state is not captured.", details: ["stage"] },
  ],
};
