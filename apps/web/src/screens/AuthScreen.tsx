import { useState } from "react";
import { signInWithMagicLink, signInWithPassword, signUpWithPassword } from "../lib/auth";
import "./AuthScreen.css";

type Mode = "signin" | "signup" | "magiclink";

export function AuthScreen() {
  const [mode, setMode] = useState<Mode>("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setNotice(null);
    setLoading(true);
    try {
      if (mode === "signup") {
        const { error: err } = await signUpWithPassword(email, password, fullName);
        if (err) throw err;
        setNotice("Account created — check your email to confirm, then sign in.");
      } else if (mode === "signin") {
        const { error: err } = await signInWithPassword(email, password);
        if (err) throw err;
      } else {
        const { error: err } = await signInWithMagicLink(email);
        if (err) throw err;
        setNotice("Magic link sent — check your email.");
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-screen">
      <div className="auth-card fade-in-up">
        <span className="auth-wordmark">
          NYAYA<span className="site-wordmark-dot">·</span>AGENT
        </span>
        <h1 className="auth-title">
          {mode === "signup" ? "Create your account" : "Welcome back"}
        </h1>
        <p className="auth-sub">
          {mode === "magiclink"
            ? "We'll email you a one-time sign-in link."
            : "Track cases, get AI-assisted statute matching, and connect with verified advocates."}
        </p>

        <form onSubmit={handleSubmit} className="auth-form">
          {mode === "signup" && (
            <input
              className="auth-input"
              type="text"
              placeholder="Full name"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              required
            />
          )}
          <input
            className="auth-input"
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          {mode !== "magiclink" && (
            <input
              className="auth-input"
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              minLength={6}
              required
            />
          )}

          <button type="submit" className="auth-submit" disabled={loading}>
            {loading ? (
              <span className="analyze-spinner" aria-hidden="true" />
            ) : mode === "signup" ? (
              "Sign up"
            ) : mode === "magiclink" ? (
              "Send magic link"
            ) : (
              "Sign in"
            )}
          </button>
        </form>

        {error && <p className="auth-error">{error}</p>}
        {notice && <p className="auth-notice">{notice}</p>}

        <div className="auth-switch">
          {mode !== "signin" && (
            <button type="button" onClick={() => setMode("signin")}>
              Sign in with password
            </button>
          )}
          {mode !== "signup" && (
            <button type="button" onClick={() => setMode("signup")}>
              Create an account
            </button>
          )}
          {mode !== "magiclink" && (
            <button type="button" onClick={() => setMode("magiclink")}>
              Use a magic link instead
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
