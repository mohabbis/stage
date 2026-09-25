import { DownloadButton } from "@/components/download-button";
import { StageDemo } from "@/components/stage-demo";

export default function HomePage() {
  return (
    <main className="page">
      <nav className="nav">
        <div className="word">Stage</div>
        <DownloadButton />
      </nav>
      <section className="hero">
        <div>
          <h1>Put the desk back.</h1>
          <p className="lede">
            Stage saves the applications, windows, tabs, and folders spread across your displays, then restores that workspace in one action.
          </p>
          <div className="actions">
            <DownloadButton />
            <a className="quiet" href="#demo">Try the preview</a>
          </div>
          <p className="note">Native macOS 15 and later. Local only. No account.</p>
        </div>
        <div id="demo">
          <StageDemo />
        </div>
      </section>
      <section className="section">
        <article>
          <h2>Full</h2>
          <p>Window frames, and the tabs, folders, directories, or documents the app actually exposed.</p>
        </article>
        <article>
          <h2>Partial</h2>
          <p>The layout comes back. Stage says when tabs, notes, or unsaved editor state could not.</p>
        </article>
        <article>
          <h2>Unsupported</h2>
          <p>If macOS will not give Stage a window, it does not pretend the desk was restored.</p>
        </article>
      </section>
      <footer>Workspaces stay on the Mac. The notarized download is served from DOWNLOAD_URL once that secret is set.</footer>
    </main>
  );
}
