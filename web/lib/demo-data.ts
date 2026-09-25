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
    id: "research",
    name: "Research",
    fidelity: "Full",
    displays: [
      {
        id: "d1",
        name: "Built-in",
        x: 0,
        y: 0,
        w: 1600,
        h: 1000,
        windows: [
          { id: "safari", app: "Safari", title: "Papers", x: 0, y: 0, w: 960, h: 1000, tone: "#1e4d63" },
          { id: "preview", app: "Preview", title: "paper.pdf", x: 960, y: 0, w: 640, h: 1000, tone: "#6a4630" },
        ],
      },
      {
        id: "d2",
        name: "Studio Display",
        x: 1680,
        y: 40,
        w: 1440,
        h: 900,
        windows: [
          { id: "notes", app: "Notes", title: "Outline", x: 1696, y: 56, w: 680, h: 400, tone: "#7d6840" },
          { id: "spotify", app: "Spotify", title: "Focus", x: 2420, y: 56, w: 680, h: 400, tone: "#1a6240" },
          { id: "terminal", app: "Terminal", title: "~/code/research", x: 1696, y: 490, w: 1408, h: 430, tone: "#1a221e" },
        ],
      },
    ],
    apps: [
      { name: "Safari", fidelity: "Full", note: "Window layout and tabs.", details: ["Papers", "Sources", "Left 60%"] },
      { name: "Preview", fidelity: "Full", note: "Window layout and the open PDF.", details: ["paper.pdf", "Right 40%"] },
      { name: "Terminal", fidelity: "Full", note: "Window layout and the working directory.", details: ["~/code/research"] },
      { name: "Notes", fidelity: "Partial", note: "The window returns. The open note does not.", details: ["Outline"] },
      { name: "Spotify", fidelity: "Full", note: "Window layout.", details: ["Focus"] },
    ],
  },
  {
    id: "writing",
    name: "Writing",
    fidelity: "Partial",
    displays: [
      {
        id: "w1",
        name: "Built-in",
        x: 0,
        y: 0,
        w: 1600,
        h: 1000,
        windows: [
          { id: "pages", app: "Pages", title: "Draft", x: 40, y: 40, w: 980, h: 920, tone: "#3a4760" },
          { id: "finder", app: "Finder", title: "Research", x: 1060, y: 80, w: 500, h: 640, tone: "#343e48" },
        ],
      },
    ],
    apps: [
      { name: "Pages", fidelity: "Partial", note: "The window returns. The document comes back when the app exposes a path.", details: ["Draft"] },
      { name: "Finder", fidelity: "Full", note: "Window layout and the open folder.", details: ["~/Documents/Research"] },
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
      name: "Built-in",
      x: 0,
      y: 0,
      w: 1600,
      h: 1000,
      windows: [
        { id: "mail", app: "Mail", title: "Inbox", x: 48, y: 48, w: 720, h: 900, tone: "#2d4458" },
        { id: "code", app: "Cursor", title: "stage", x: 820, y: 64, w: 720, h: 860, tone: "#2a2926" },
      ],
    },
  ],
  apps: [
    { name: "Mail", fidelity: "Full", note: "Window layout.", details: ["Inbox"] },
    { name: "Cursor", fidelity: "Partial", note: "The project folder returns. Unsaved editor state does not.", details: ["stage"] },
  ],
};
