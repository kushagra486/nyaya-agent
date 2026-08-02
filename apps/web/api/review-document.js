// Document clause review proxy - same server-side GROQ_API_KEY pattern as
// api/analyze.js and api/chat.js. Accepts extracted document text (the
// browser does PDF/DOCX text extraction client-side via pdf.js/mammoth.js
// before calling this), and returns clause-level risk analysis.

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const MODEL = "llama-3.3-70b-versatile";
const MAX_TEXT_CHARS = 12000;

const hits = new Map();
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 6;

function throttled(ip) {
  const now = Date.now();
  const entry = hits.get(ip);
  if (!entry || now - entry.start > WINDOW_MS) {
    hits.set(ip, { start: now, count: 1 });
    return false;
  }
  entry.count += 1;
  return entry.count > MAX_PER_WINDOW;
}

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) {
    return res.status(500).json({
      error: "Server is missing GROQ_API_KEY. Set it in Vercel → Project Settings → Environment Variables, then redeploy.",
    });
  }

  const ip = req.headers["x-forwarded-for"]?.split(",")[0]?.trim() || "unknown";
  if (throttled(ip)) {
    return res.status(429).json({ error: "Too many requests — please wait a minute and try again." });
  }

  const { documentText } = req.body || {};
  if (typeof documentText !== "string" || !documentText.trim()) {
    return res.status(400).json({ error: "documentText is required." });
  }

  const safeText = documentText.slice(0, MAX_TEXT_CHARS);

  const systemPrompt = `You are a document-review assistant for Indian legal documents (contracts, agreements, notices). Not a lawyer - this is informational review, not legal advice.
Break the document into its distinct clauses/sections and evaluate each one against a fixed rubric: what obligation it creates, whether it's an unusual or one-sided term, and a risk level.
Respond with STRICT JSON only, no markdown fences, matching this exact shape:
{
  "clauses": [
    {"clause_text": "short quote or paraphrase of the clause (max ~25 words)", "risk_level": "low|medium|high", "explanation": "one plain-English line: what this clause obligates and why it's flagged at this risk level"}
  ],
  "summary": "one or two sentence overall summary of the document's risk profile",
  "disclaimer": "This is an AI-assisted review for informational purposes, not legal advice — have a licensed advocate review this document before signing or filing."
}
Flag as "high" risk: unlimited liability, unilateral termination rights favoring one party, automatic renewal without notice, broad indemnification, non-standard penalty clauses.
Flag as "medium": ambiguous terms, missing standard protections, one-sided but common terms.
Flag as "low": standard, mutual, unremarkable terms.
If the document has no clearly divisible clauses (e.g. it's a short letter), treat each paragraph as one clause.`;

  try {
    const groqRes = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 0.2,
        max_tokens: 1500,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: safeText },
        ],
      }),
    });

    if (!groqRes.ok) {
      const body = await groqRes.text().catch(() => "");
      return res.status(502).json({ error: `Groq API error ${groqRes.status}: ${body.slice(0, 300)}` });
    }

    const data = await groqRes.json();
    const text = data?.choices?.[0]?.message?.content ?? "{}";
    return res.status(200).json({ result: text });
  } catch (err) {
    return res.status(500).json({ error: err instanceof Error ? err.message : "Unknown server error." });
  }
}
