import { useEffect, useState } from "react";
import { listCases } from "../lib/db";
import type { CaseRecord } from "../lib/dbTypes";
import "./DashboardScreen.css";

interface Props {
  userId: string;
  onOpenCase: (caseId: string) => void;
}

export function HistoryScreen({ userId, onOpenCase }: Props) {
  const [cases, setCases] = useState<CaseRecord[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    listCases(userId)
      .then(setCases)
      .finally(() => setLoading(false));
  }, [userId]);

  return (
    <div className="dashboard-screen">
      <header className="dashboard-header">
        <span className="dashboard-wordmark">Legal History</span>
      </header>

      <div className="dashboard-body fade-in-up" style={{ paddingBottom: "6rem" }}>
        {loading && <p className="dashboard-empty">Loading…</p>}
        {!loading && cases.length === 0 && (
          <p className="dashboard-empty">No past cases yet.</p>
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
      </div>
    </div>
  );
}
