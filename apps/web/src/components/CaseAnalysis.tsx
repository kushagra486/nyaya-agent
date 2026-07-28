import { useState } from "react";
import { scoreCandidates } from "../lib/search";
import { analyzeCase } from "../lib/groq";
import "./CaseAnalysis.css";

export function CaseAnalysis() {
  const [caseText, setCaseText] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<string | null>(null);

  async function handleAnalyze() {
    setError(null);
    setResult(null);

    if (!caseText.trim()) {
      setError("Describe your situation in a sentence or two first.");
      return;
    }

    setLoading(true);
    try {
      const candidates = scoreCandidates(caseText);
      const { raw } = await analyzeCase(caseText.trim(), candidates);
      setResult(raw);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong reaching the analysis service.");
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
        section-mapping dataset, then asks Llama 3.3 70B (via Groq) to explain
        the likely current-law sections — grounded only in matches it finds,
        never invented. Free to use, no account or key needed.
      </p>

      <textarea
        className="case-textarea"
        rows={4}
        placeholder="e.g. My landlord is refusing to return my security deposit two months after I vacated the flat in Lucknow…"
        value={caseText}
        onChange={(e) => setCaseText(e.target.value)}
      />

      <button type="button" className="analyze-btn" onClick={handleAnalyze} disabled={loading}>
        {loading ? (
          <>
            <span className="analyze-spinner" aria-hidden="true" />
            Analyzing
          </>
        ) : (
          "Analyze"
        )}
      </button>

      {error && <p className="case-error">{error}</p>}

      {result && (
        <div className="case-result fade-in-up">
          <span className="case-result-badge">Analyzed</span>
          <pre className="case-result-text">{result}</pre>
        </div>
      )}
    </section>
  );
}
