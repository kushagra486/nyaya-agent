import "./Chrome.css";

export function DisclaimerBanner() {
  return (
    <div className="disclaimer-banner" role="note">
      <span className="disclaimer-mark">§</span>
      Nyaya-Agent provides legal information based on Indian statutes. It is{" "}
      <strong>not</strong> a substitute for professional legal advice.
    </div>
  );
}

export function SiteHeader({ onSignIn }: { onSignIn: () => void }) {
  return (
    <header className="site-header">
      <span className="site-wordmark">
        NYAYA<span className="site-wordmark-dot">·</span>AGENT
      </span>
      <div className="site-header-actions">
        <button type="button" className="site-signin-link" onClick={onSignIn}>
          Sign in
        </button>
        <a
          className="site-github-link"
          href="https://github.com/kushagra486/nyaya-agent"
          target="_blank"
          rel="noreferrer"
        >
          View on GitHub
        </a>
      </div>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <p>
        Open source under the MIT License —{" "}
        <a href="https://github.com/kushagra486/nyaya-agent" target="_blank" rel="noreferrer">
          github.com/kushagra486/nyaya-agent
        </a>
      </p>
      <p className="site-footer-muted">
        Covers BNS 2023, BNSS 2023, BSA 2023 and their IPC/CrPC/Evidence Act
        predecessors. Not affiliated with the Government of India or the Bar
        Council of India.
      </p>
    </footer>
  );
}
