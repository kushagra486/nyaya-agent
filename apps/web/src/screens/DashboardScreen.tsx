import { useEffect, useState } from "react";
import { listCases, createCase } from "../lib/db";
import type { CaseRecord } from "../lib/dbTypes";
import "./DashboardScreen.css";

interface Props {
  userId: string;
  onOpenCase: (caseId: string) => void;
  onOpenLawyers: () => void;
}

export function DashboardScreen({ userId, onOpenCase, onOpenLawyers }: Props) {
  const [cases, setCases] = useState<CaseRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [showIntake, setShowIntake] = useState(false);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function refresh() {
    setLoading(true);
    try {
      setCases(await listCases(userId));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load cases.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId]);

  async function handleCreate() {
    if (!title.trim() || !description.trim()) {
      setError("Give the case a title and a short description first.");
      return;
    }
    setCreating(true);
    setError(null);
    try {
      const created = await createCase(userId, title.trim(), description.trim());
      setShowIntake(false);
      setTitle("");
      setDescription("");
      await refresh();
      onOpenCase(created.id);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not create the case.");
    } finally {
      setCreating(false);
    }
  }

  return (
    <div className="dashboard-screen">
      <header className="dashboard-header">
        <span className="dashboard-wordmark">
          <span className="dashboard-scale-icon" aria-hidden="true">⚖️</span> NYAYA
          <span className="site-wordmark-dot">·</span>AGENT
        </span>
        <span className="dashboard-bell" aria-label="Notifications" role="img">🔔</span>
      </header>

      <div className="dashboard-body fade-in-up">
        <h1 className="dashboard-title">My Case Dashboard</h1>

        <div className="dashboard-quick-access">
          <button type="button" className="quick-chip" onClick={onOpenLawyers}>
            Find Lawyers
          </button>
        </div>

        {loading && <p className="dashboard-empty">Loading your cases…</p>}

        {!loading && cases.length === 0 && (
          <p className="dashboard-empty">
            No cases yet — start one below and get an instant AI read on the relevant statutes.
          </p>
        )}

        <div className="case-list">
          {cases.map((c) => (
            <button
              type="button"
              key={c.id}
              className="case-card"
              onClick={() => onOpenCase(c.id)}
            >
              <span className={`case-status-bar case-status-${c.status}`} />
              <span className="case-card-body">
                <span className="case-card-title">{c.title}</span>
                <span className={`case-card-status case-card-status-${c.status}`}>
                  {c.status === "analyzed" ? "Analyzed" : "Draft"}
                </span>
              </span>
              <span className="case-card-chevron" aria-hidden="true">›</span>
            </button>
          ))}
        </div>

        {error && <p className="dashboard-error">{error}</p>}

        {!showIntake ? (
          <>
            <div className="intake-options-row">
              <button type="button" className="intake-option intake-option-disabled" disabled title="Coming soon">
                <span className="intake-option-icon" aria-hidden="true">📄</span>
                Upload Document
              </button>
              <button type="button" className="intake-option" onClick={() => setShowIntake(true)}>
                <span className="intake-option-icon" aria-hidden="true">📝</span>
                Describe Case
              </button>
            </div>
            <button type="button" className="new-case-btn" onClick={() => setShowIntake(true)}>
              + New Case
            </button>
          </>
        ) : (
          <div className="intake-panel fade-in-up">
            <p className="intake-label">Describe Case</p>
            <input
              className="intake-input"
              placeholder="Give it a short title (e.g. Landlord deposit dispute)"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
            <textarea
              className="intake-textarea"
              rows={4}
              placeholder="Describe what happened in plain language…"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
            <div className="intake-actions">
              <button type="button" className="intake-cancel" onClick={() => setShowIntake(false)}>
                Cancel
              </button>
              <button type="button" className="intake-submit" onClick={handleCreate} disabled={creating}>
                {creating ? <span className="analyze-spinner" aria-hidden="true" /> : "Create case"}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
