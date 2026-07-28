import { useMemo, useState } from "react";
import { findBySection } from "../lib/search";
import { RepealedStamp, InForceSeal } from "./Seals";
import "./Correlator.css";

export function Correlator() {
  const [query, setQuery] = useState("");

  const results = useMemo(() => findBySection(query), [query]);

  return (
    <section className="correlator" aria-label="Section correlator">
      <p className="correlator-eyebrow">Section Correlator</p>
      <h1 className="correlator-headline">
        The law renumbered itself.
        <br />
        <span className="correlator-headline-em">We kept the paper trail.</span>
      </h1>
      <p className="correlator-sub">
        Type any section number — old or new. IPC, CrPC, and the Evidence Act
        on one side; BNS, BNSS, and BSA on the other.
      </p>

      <div className="correlator-input-row">
        <span className="correlator-input-glyph">§</span>
        <input
          className="correlator-input"
          type="text"
          inputMode="text"
          placeholder="e.g. 302, 420, 154, 65B, 103…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          aria-label="Enter a section number"
        />
      </div>

      <div className="correlator-results" role="status">
        {query.trim() && results.length === 0 && (
          <p className="correlator-empty">
            No match for "{query.trim()}" in the current dataset — try a section
            like 302, 420, or 154, or browse the full table below.
          </p>
        )}

        {results.map((r) => (
          <div className="correlator-card" key={r.id}>
            <div className="correlator-side correlator-side-old">
              <RepealedStamp />
              <p className="correlator-side-act">{r.oldAct}</p>
              <p className="correlator-side-section">§{r.oldSection}</p>
            </div>

            <div className="correlator-arrow" aria-hidden="true">
              →
            </div>

            <div className="correlator-side correlator-side-new">
              <InForceSeal />
              <p className="correlator-side-act">{r.newAct}</p>
              <p className="correlator-side-section">§{r.newSection}</p>
            </div>

            <div className="correlator-meta">
              <p className="correlator-title">{r.title}</p>
              {r.notes && <p className="correlator-notes">{r.notes}</p>}
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
