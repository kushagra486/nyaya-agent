import type { StatuteRecord } from "./types";

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const MODEL = "llama-3.3-70b-versatile";

export interface AnalysisResult {
  raw: string;
}

/**
 * Calls Groq directly from the browser using a key the visitor supplies and
 * holds only in their own localStorage — this app never transmits your key
 * anywhere but api.groq.com, and it is never bundled or committed to the repo.
 */
export async function analyzeCase(
  apiKey: string,
  caseText: string,
  candidates: StatuteRecord[]
): Promise<AnalysisResult> {
  const groundingBlock = candidates
    .map(
      (c) =>
        `- ${c.title} — old: Sec ${c.oldSection} ${c.oldAct}; current: Sec ${c.newSection} ${c.newAct}. ${c.notes}`
    )
    .join("\n");

  const systemPrompt = `You are a legal-information assistant for Indian law, not a lawyer.
Ground every statute you mention ONLY in the candidate list below — never invent a section number.
If nothing in the candidate list is a good fit, say so plainly instead of guessing.
For each relevant candidate, state: the current-law section (BNS/BNSS/BSA), the old-law section in brackets, a one-line plain-English explanation, and a rough confidence (high/medium/low).
Then suggest concrete next steps (e.g. which forum or authority to approach) in plain language.
End with exactly this line: "This is legal information, not legal advice — consult a licensed advocate for your specific case."

Candidate sections (only cite from this list):
${groundingBlock || "(no strong candidates found in the local dataset)"}`;

  const response = await fetch(GROQ_ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MODEL,
      temperature: 0.2,
      max_tokens: 900,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: caseText },
      ],
    }),
  });

  if (!response.ok) {
    const body = await response.text().catch(() => "");
    throw new Error(`Groq API error ${response.status}: ${body.slice(0, 300)}`);
  }

  const data = await response.json();
  const text: string = data?.choices?.[0]?.message?.content ?? "No response generated.";
  return { raw: text };
}
