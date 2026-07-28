import type { StatuteRecord } from "./types";

export interface AnalysisResult {
  raw: string;
}

/**
 * Calls our own /api/analyze serverless function, which holds the Groq key
 * server-side (Vercel encrypted env var). The browser never sees the key —
 * it only ever talks to our own domain.
 */
export async function analyzeCase(
  caseText: string,
  candidates: StatuteRecord[]
): Promise<AnalysisResult> {
  const response = await fetch("/api/analyze", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ caseText, candidates }),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data?.error || `Request failed (${response.status})`);
  }

  return { raw: data.result ?? "No response generated." };
}
