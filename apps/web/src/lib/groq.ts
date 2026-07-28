import type { StatuteRecord } from "./types";

export interface AnalysisResult {
  raw: string;
}

export interface StructuredAnalysis {
  facts: string[];
  statutes: Array<{
    citation: string;
    oldCitation?: string;
    title?: string;
    explanation: string;
    confidence?: "high" | "medium" | "low";
  }>;
  steps: string[];
  disclaimer?: string;
}

/**
 * The analyze endpoint returns JSON (facts/statutes/steps). Older saved
 * cases may have plain text from before this format existed, so this
 * returns null rather than throwing when the content isn't parseable —
 * callers fall back to rendering the raw text in that case.
 */
export function parseStructuredAnalysis(raw: string): StructuredAnalysis | null {
  try {
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed.facts) && Array.isArray(parsed.statutes) && Array.isArray(parsed.steps)) {
      return parsed as StructuredAnalysis;
    }
    return null;
  } catch {
    return null;
  }
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

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

/**
 * Calls /api/chat — the multi-turn counterpart of /api/analyze. Sends the
 * running conversation plus the original case description as context, so
 * follow-ups stay grounded in the same case.
 */
export async function chatWithAgent(
  caseContext: string,
  history: ChatMessage[]
): Promise<AnalysisResult> {
  const response = await fetch("/api/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ caseContext, history }),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data?.error || `Request failed (${response.status})`);
  }

  return { raw: data.result ?? "No response generated." };
}
