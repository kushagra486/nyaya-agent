import { useEffect, useMemo, useState } from "react";
import { listLawyers, requestConsultation } from "../lib/db";
import type { LawyerRecord } from "../lib/dbTypes";
import "./LawyersScreen.css";

interface Props {
  userId: string;
  activeCaseId: string | null;
  onBack: () => void;
}

const SPECIALIZATIONS = ["Civil", "Criminal", "Family", "Cyber", "Corporate"];

function initials(name: string): string {
  const parts = name.replace(/^Adv\.\s*/i, "").split(" ").filter(Boolean);
  return parts.slice(0, 2).map((p) => p[0]).join("").toUpperCase();
}

export function LawyersScreen({ userId, activeCaseId, onBack }: Props) {
  const [lawyers, setLawyers] = useState<LawyerRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string | null>(null);
  const [courtFilter, setCourtFilter] = useState("");
  const [minExperience, setMinExperience] = useState(0);
  const [requestedId, setRequestedId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    listLawyers()
      .then(setLawyers)
      .catch((e) => setError(e instanceof Error ? e.message : "Could not load lawyers."))
      .finally(() => setLoading(false));
  }, []);

  const courts = useMemo(() => {
    const set = new Set<string>();
    lawyers.forEach((l) => l.court_practices?.forEach((c) => set.add(c)));
    return Array.from(set).sort();
  }, [lawyers]);

  const filtered = useMemo(() => {
    return lawyers.filter((l) => {
      if (filter && !l.specializations?.includes(filter)) return false;
      if (courtFilter && !l.court_practices?.includes(courtFilter)) return false;
      if (l.experience_years < minExperience) return false;
      return true;
    });
  }, [lawyers, filter, courtFilter, minExperience]);

  async function handleRequest(lawyerId: string) {
    if (!activeCaseId) {
      setError("Open a case first, then request a consultation from there.");
      return;
    }
    try {
      const preferredTime = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
      await requestConsultation(activeCaseId, userId, lawyerId, preferredTime);
      setRequestedId(lawyerId);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not send the request.");
    }
  }

  return (
    <div className="lawyers-screen">
      <header className="chat-header">
        <button type="button" className="analysis-back" onClick={onBack} aria-label="Back">
          ‹
        </button>
        <span className="chat-case-title">Verify &amp; Book Lawyer</span>
      </header>

      <div className="lawyers-body fade-in-up">
        <div className="lawyers-filters">
          <button
            type="button"
            className={`spec-chip ${filter === null ? "spec-chip-active" : ""}`}
            onClick={() => setFilter(null)}
          >
            All
          </button>
          {SPECIALIZATIONS.map((s) => (
            <button
              type="button"
              key={s}
              className={`spec-chip ${filter === s ? "spec-chip-active" : ""}`}
              onClick={() => setFilter(s)}
            >
              {s}
            </button>
          ))}
        </div>

        <div className="lawyers-dropdowns">
          <select
            className="lawyer-dropdown"
            value={courtFilter}
            onChange={(e) => setCourtFilter(e.target.value)}
          >
            <option value="">All courts</option>
            {courts.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
          <select
            className="lawyer-dropdown"
            value={minExperience}
            onChange={(e) => setMinExperience(Number(e.target.value))}
          >
            <option value={0}>Any experience</option>
            <option value={5}>5+ years</option>
            <option value={10}>10+ years</option>
            <option value={15}>15+ years</option>
          </select>
        </div>

        {loading && <p className="dashboard-empty">Loading lawyers…</p>}
        {error && <p className="dashboard-error">{error}</p>}

        <div className="lawyer-list">
          {filtered.map((l) => (
            <div className="lawyer-card" key={l.id}>
              <div className="lawyer-card-top">
                <div className="lawyer-identity">
                  <span className="lawyer-avatar" aria-hidden="true">{initials(l.name)}</span>
                  <span className="lawyer-name">{l.name}</span>
                </div>
                {l.is_verified && <span className="verified-badge">✓ Verified</span>}
              </div>
              <p className="lawyer-meta">
                {l.bar_council_reg_no} · {l.experience_years} yrs experience · ₹{l.consultation_fee}/hr
              </p>
              <div className="lawyer-tags">
                {l.specializations?.map((s) => (
                  <span key={s} className="lawyer-tag">{s}</span>
                ))}
              </div>
              <button
                type="button"
                className="request-btn"
                onClick={() => handleRequest(l.id)}
                disabled={requestedId === l.id}
              >
                {requestedId === l.id ? "Request Sent" : "Share Case & Request Consultation"}
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
