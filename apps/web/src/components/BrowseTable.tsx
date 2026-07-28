import { useMemo, useState } from "react";
import { allStatutes } from "../lib/search";
import { GROUP_LABEL } from "../lib/types";
import type { StatuteRecord } from "../lib/types";
import "./BrowseTable.css";

const GROUPS: Array<StatuteRecord["group"] | "all"> = ["all", "criminal", "procedure", "evidence"];

export function BrowseTable() {
  const [group, setGroup] = useState<StatuteRecord["group"] | "all">("all");
  const [filter, setFilter] = useState("");

  const rows = useMemo(() => {
    const all = allStatutes();
    const byGroup = group === "all" ? all : all.filter((r) => r.group === group);
    const q = filter.trim().toLowerCase();
    if (!q) return byGroup;
    return byGroup.filter(
      (r) =>
        r.title.toLowerCase().includes(q) ||
        r.oldSection.toLowerCase().includes(q) ||
        r.newSection.toLowerCase().includes(q)
    );
  }, [group, filter]);

  return (
    <section className="browse" aria-label="Browse all section mappings" id="browse">
      <p className="section-eyebrow">Full Register</p>
      <h2 className="section-headline">Browse every mapping.</h2>

      <div className="browse-controls">
        <div className="browse-tabs" role="tablist">
          {GROUPS.map((g) => (
            <button
              key={g}
              type="button"
              role="tab"
              aria-selected={group === g}
              className={`browse-tab ${group === g ? "browse-tab-active" : ""}`}
              onClick={() => setGroup(g)}
            >
              {g === "all" ? "All" : GROUP_LABEL[g]}
            </button>
          ))}
        </div>
        <input
          className="browse-filter"
          type="text"
          placeholder="Filter by keyword or section…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        />
      </div>

      <div className="browse-table-wrap">
        <table className="browse-table">
          <thead>
            <tr>
              <th>Offence / provision</th>
              <th>Old section</th>
              <th>Current section</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td>
                  <span className="browse-title">{r.title}</span>
                  <span className="browse-group">{GROUP_LABEL[r.group]}</span>
                </td>
                <td className="browse-mono browse-old">
                  §{r.oldSection}
                  <span className="browse-act">{r.oldAct}</span>
                </td>
                <td className="browse-mono browse-new">
                  §{r.newSection}
                  <span className="browse-act">{r.newAct}</span>
                </td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr>
                <td colSpan={3} className="browse-empty">
                  No entries match "{filter}".
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <p className="browse-footnote">
        {rows.length} of {allStatutes().length} sections shown — this is a seed
        dataset covering the most commonly cited provisions, not the complete
        bare acts. See the repo README to extend it.
      </p>
    </section>
  );
}
