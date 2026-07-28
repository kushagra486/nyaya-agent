import { useEffect, useState } from "react";
import { getCase, updateCaseAnalysis } from "../lib/db";
import { scoreCandidates } from "../lib/search";
import { analyzeCase, parseStructuredAnalysis } from "../lib/groq";
import type { CaseRecord } from "../lib/dbTypes";
import "./AnalysisScreen.css";

interface Props {
  caseId: string;
  onBack: () => void;
  onOpenChat: () => void;
}

const CONFIDENCE_LABEL: Record<string, string> = {
  high: "High confidence",
  medium: "Medium confidence",
  low: "Low confidence",
};

export function AnalysisScreen({ caseId, onBack, onOpenChat }: Props) {
  const [record, setRecord] = useState<CaseRecord | null>(null);
  const [loading, setLoading] = useState(true);
  const [analyzing, setAnalyzing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    try {
      setRecord(await getCase(caseId));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load this case.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [caseId]);

  async function handleAnalyze() {
    if (!record) return;
    setAnalyzing(true);
    setError(null);
    try {
      const candidates = scoreCandidates(record.raw_description);
      const { raw } = await analyzeCase(record.raw_description, candidates);
      await updateCaseAnalysis(caseId, raw);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Analysis failed.");
    } finally {
      setAnalyzing(false);
    }
  }

  if (loading) {
    return <div className="analysis-screen"><p className="analysis-loading">Loading case…</p></div>;
  }
  if (!record) {
    return <div className="analysis-screen"><p className="analysis-loading">Case not found.</p></div>;
  }

  const structured = record.ai_analysis ? parseStructuredAnalysis(record.ai_analysis) : null;

  return (
    <div className="analysis-screen">
      <header className="analysis-header">
        <button type="button" className="analysis-back" onClick={onBack} aria-label="Back to dashboard">
          ‹
        </button>
        <div className="analysis-header-body">
          <span className="analysis-case-title">{record.title}</span>
          <span className={`analysis-status-badge analysis-status-${record.status}`}>
            {record.status === "analyzed" ? "Analyzed" : "Draft"}
          </span>
        </div>
      </header>

      <div className="analysis-body fade-in-up">
        <div className="analysis-card">
          <p className="analysis-card-label">Facts</p>
          {structured ? (
            <ul className="analysis-facts-list">
              {structured.facts.map((f, i) => <li key={i}>{f}</li>)}
            </ul>
          ) : (
            <p className="analysis-card-text">{record.raw_description}</p>
          )}
        </div>

        {!record.ai_analysis && (
          <button type="button" className="analyze-btn" onClick={handleAnalyze} disabled={analyzing}>
            {analyzing ? (
              <>
                <span className="analyze-spinner" aria-hidden="true" />
                Analyzing
              </>
            ) : (
              "Analyze"
            )}
          </button>
        )}

        {error && <p className="analysis-error">{error}</p>}

        {record.ai_analysis && structured && (
          <>
            <div className="analysis-card analysis-card-result fade-in-up">
              <p className="analysis-card-label">Relevant Statutes</p>
              {structured.statutes.length === 0 && (
                <p className="analysis-card-text">No confident statute match found in the local dataset.</p>
              )}
              <div className="statute-citations">
                {structured.statutes.map((s, i) => (
                  <div className="statute-citation" key={i}>
                    <div className="statute-citation-top">
                      <span className="statute-citation-code">{s.citation}</span>
                      {s.oldCitation && <span className="statute-citation-old">({s.oldCitation})</span>}
                      {s.confidence && (
                        <span className={`statute-confidence statute-confidence-${s.confidence}`}>
                          {CONFIDENCE_LABEL[s.confidence] ?? s.confidence}
                        </span>
                      )}
                    </div>
                    {s.title && <p className="statute-citation-title">{s.title}</p>}
                    <p className="statute-citation-explanation">{s.explanation}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="analysis-card fade-in-up">
              <p className="analysis-card-label">Suggested Steps</p>
              <ol className="analysis-steps-list">
                {structured.steps.map((s, i) => <li key={i}>{s}</li>)}
              </ol>
            </div>

            {structured.disclaimer && (
              <p className="analysis-disclaimer">{structured.disclaimer}</p>
            )}
          </>
        )}

        {record.ai_analysis && !structured && (
          <div className="analysis-card analysis-card-result fade-in-up">
            <p className="analysis-card-label">Relevant Statutes &amp; Suggested Steps</p>
            <pre className="analysis-result-text">{record.ai_analysis}</pre>
          </div>
        )}
      </div>

      {record.ai_analysis && (
        <button type="button" className="chat-fab" onClick={onOpenChat} aria-label="Chat with agent">
          💬
        </button>
      )}
    </div>
  );
}
