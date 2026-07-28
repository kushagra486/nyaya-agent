import statutes from "../data/statutes.json";
import type { StatuteRecord } from "./types";

const DATA = statutes as StatuteRecord[];

/** Exact/prefix match on a section number, old or new code, either side. */
export function findBySection(query: string): StatuteRecord[] {
  const q = query.trim().toLowerCase();
  if (!q) return [];
  return DATA.filter(
    (r) =>
      r.oldSection.toLowerCase() === q ||
      r.newSection.toLowerCase() === q ||
      r.oldSection.toLowerCase().startsWith(q) ||
      r.newSection.toLowerCase().startsWith(q)
  );
}

const STOPWORDS = new Set([
  "the", "a", "an", "of", "to", "in", "on", "and", "or", "my", "me", "is",
  "was", "were", "he", "she", "they", "with", "by", "for", "at", "from",
  "has", "have", "had", "i", "his", "her", "their", "it", "that", "this",
]);

function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((t) => t.length > 2 && !STOPWORDS.has(t));
}

/**
 * Very lightweight keyword-overlap scorer — this is a client-side stand-in
 * for the vector similarity search described in the RAG spec. It surfaces
 * candidate sections whose title/notes share vocabulary with the case
 * description, so the LLM call has grounded, real section numbers to cite
 * instead of inventing them.
 */
export function scoreCandidates(caseText: string, topN = 6): StatuteRecord[] {
  const queryTokens = new Set(tokenize(caseText));
  if (queryTokens.size === 0) return [];

  const scored = DATA.map((record) => {
    const haystack = tokenize(`${record.title} ${record.notes}`);
    let score = 0;
    for (const token of haystack) {
      if (queryTokens.has(token)) score += 1;
    }
    return { record, score };
  }).filter((s) => s.score > 0);

  scored.sort((a, b) => b.score - a.score);
  return scored.slice(0, topN).map((s) => s.record);
}

export function allStatutes(): StatuteRecord[] {
  return DATA;
}
