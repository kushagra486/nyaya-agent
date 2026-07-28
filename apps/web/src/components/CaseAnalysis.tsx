import { useState } from "react";
import { scoreCandidates } from "../lib/search";
import { analyzeCase } from "../lib/groq";
import "./CaseAnalysis.css";

const KEY_STORAGE = "nyaya-agent:groq-key";

export function CaseAnalysis() {
  const [apiKey, setApiKey] = useState(() => localStorage.getItem(KEY_STORAGE) ?? "");
  const [showKeyField, setShowKeyField] = useState(!apiKey);
  const [caseText, setCaseText] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<string | null>(null);

  function saveKey(value: string) {
    setApiKey(value);
    localStorage.setItem(KEY_STORAGE, value);
  }

  async function handleAnalyze() {
    setError(null);
    setResult(null);

    if (!apiKey.trim()) {
      setError("Add your free Groq API key first — it stays in your browser only.");
      setShowKeyField(true);
      return;
    }
    if (!caseText.trim()) {
      setError("Describe your situation in a sentence or two first.");
      return;
    }

    setLoading(true);
    try {
      const candidates = scoreCandidates(caseText);
      const { raw } = await analyzeCase(apiKey.trim(), caseText.trim(), candidates);
      setResult(raw);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong calling Groq.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="case-analysis" aria-label="Describe your situation">
      <p className="section-eyebrow">Statute Matching</p>
      <h2 className="section-headline">Describe what happened.</h2>
      <p className="section-sub">
        Plain language is fine. This checks your description against the local
        section-mapping dataset, then asks Groq's Llama 3.3 70B to explain the
        likely current-law sections — grounded only in matches it finds, never invented.
      </p>

      {showKeyField && (
        <div className="key-panel">
          <label className="key-label" htmlFor="groq-key">
            Groq API key
          </label>
          <div className="key-row">
            <input
              id="groq-key"
              type="password"
              className="key-input"
              placeholder="gsk_…"
              value={apiKey}
              onChange={(e) => saveKey(e.target.value)}
            />
            <button
              type="button"
              className="key-done"
              onClick={() => setShowKeyField(false)}
              disabled={!apiKey.trim()}
            >
              Done
            </button>
          </div>
          <p className="key-hint">
            Free at{" "}
            <a href="https://console.groq.com/keys" target="_blank" rel="noreferrer">
              console.groq.com/keys
            </a>
            . Stored only in this browser's localStorage — never sent anywhere but
            api.groq.com, never committed to this repo.
          </p>
        </div>
      )}

      {!showKeyField && (
        <button type="button" className="key-change" onClick={() => setShowKeyField(true)}>
          Change Groq key
        </button>
      )}

      <textarea
        className="case-textarea"
        rows={4}
        placeholder="e.g. My landlord is refusing to return my security deposit two months after I vacated the flat in Lucknow…"
        value={caseText}
        onChange={(e) => setCaseText(e.target.value)}
      />

      <button type="button" className="analyze-btn" onClick={handleAnalyze} disabled={loading}>
        {loading ? "Analyzing…" : "Analyze"}
      </button>

      {error && <p className="case-error">{error}</p>}

      {result && (
        <div className="case-result">
          <pre className="case-result-text">{result}</pre>
        </div>
      )}
    </section>
  );
}
