import { DownloadButton } from "@/components/download-button";
import { StageDemo } from "@/components/stage-demo";

const apps = ["Safari", "Chrome", "Brave", "Edge", "Arc", "Finder", "Terminal", "iTerm", "VS Code", "Cursor", "Preview"];

export default function HomePage() {
  return (
    <main className="page">
      <header className="bar">
        <nav className="nav">
          <a className="word" href="/">
            Stage
          </a>
          <div className="nav-links">
            <a className="ghost" href="#how">
              How it works
            </a>
            <DownloadButton />
          </div>
        </nav>
      </header>

      <section className="hero">
        <p className="eyebrow">Workspace memory for Mac</p>
        <h1>
          Put the desk
          <br />
          back.
        </h1>
        <p className="lede">
          Save the apps, windows, tabs, and folders across your displays. Stage restores that desk in one action, and says so when a piece cannot come back.
        </p>
        <div className="actions">
          <DownloadButton emphasis />
          <a className="quiet" href="#demo">
            Watch it restore
          </a>
        </div>
        <ul className="facts">
          <li>macOS 15 or later</li>
          <li>Stays on this Mac</li>
          <li>No account</li>
        </ul>
      </section>

      <section className="demo-wrap" id="demo">
        <StageDemo />
        <p className="caption">A preview in the browser. The Mac app does the real capture.</p>
      </section>

      <section className="steps" id="how">
        <article>
          <span>01</span>
          <h2>Save the Space</h2>
          <p>Stage records the desktop you are in: frames, plus the tabs, folders, directories, and documents macOS will expose. Other Spaces stay out of it.</p>
        </article>
        <article>
          <span>02</span>
          <h2>Leave it</h2>
          <p>Switch tasks whenever you want. Stage does not quit the apps from the saved desk. Hidden apps keep running.</p>
        </article>
        <article>
          <span>03</span>
          <h2>Put it back</h2>
          <p>One restore opens what is missing, moves windows home, and marks each app full, partial, or unsupported.</p>
        </article>
      </section>

      <section className="honest">
        <h2>Honest about every window.</h2>
        <div className="cards">
          <article>
            <span className="badge Full">Full</span>
            <h3>The window, and what was in it</h3>
            <p>Frames, plus tabs, folders, directories, and documents the app actually exposed.</p>
          </article>
          <article>
            <span className="badge Partial">Partial</span>
            <h3>The layout, with a caveat</h3>
            <p>The window comes back. Stage says when a note, tab, or unsaved editor did not.</p>
          </article>
          <article>
            <span className="badge Unsupported">Unsupported</span>
            <h3>Named, not invented</h3>
            <p>If macOS will not give Stage a window, that window stays off the restored desk.</p>
          </article>
        </div>
      </section>

      <section className="known">
        <p>Reopens what these apps will hand over</p>
        <ul>
          {apps.map((app) => (
            <li key={app}>{app}</li>
          ))}
        </ul>
      </section>

      <footer>
        <div className="word">Stage</div>
        <p>Workspaces stay on your Mac. No account. macOS 15 or later.</p>
      </footer>
    </main>
  );
}
