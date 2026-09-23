/**
 * Server-side Groq proxy.
 *
 * GROQ_API_KEY lives only in this function's environment (set in the Vercel
 * dashboard → Project Settings → Environment Variables), never in source
 * control and never sent to the browser. The frontend calls this endpoint
 * instead of api.groq.com directly, so no visitor needs their own key.
 */

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const MODEL = "openai/gpt-oss-120b";

const MAX_CASE_CHARS = 2000;
const MAX_CANDIDATES = 8;

// Best-effort per-IP throttle. Serverless instances are ephemeral so this
// resets on cold start — it's a speed bump against casual abuse, not a
// substitute for a real rate limiter (e.g. Upstash/Vercel KV) if this app
// gets real traffic.
const hits = new Map();
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 8;

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

  const { caseText, candidates, locale } = req.body || {};
  if (typeof caseText !== "string" || !caseText.trim()) {
    return res.status(400).json({ error: "caseText is required." });
  }

  const safeCaseText = caseText.slice(0, MAX_CASE_CHARS);
  const safeCandidates = Array.isArray(candidates) ? candidates.slice(0, MAX_CANDIDATES) : [];

  const groundingBlock = safeCandidates
    .map(
      (c) =>
        `- ${c.title} — old: Sec ${c.oldSection} ${c.oldAct}; current: Sec ${c.newSection} ${c.newAct}. ${c.notes ?? ""}`
    )
    .join("\n");

  const LOCALE_NAMES = { hi: "Hindi", mr: "Marathi", ta: "Tamil", en: "English" };
  const languageName = LOCALE_NAMES[locale] || "English";
  const languageLine = languageName === "English"
    ? ""
    : `\nRespond with all "facts", "description", "explanation", "steps", and "disclaimer" text values in ${languageName}, natively written (not transliterated English) - but keep "citation"/"oldCitation"/"event_date"/"confidence" values as-is (statute numbers and codes stay in their original form regardless of language).`;

  const systemPrompt = `You are a legal-information assistant for Indian law, not a lawyer.
Ground every statute you mention ONLY in the candidate list below — never invent a section number.
Respond with STRICT JSON only, no markdown fences, matching this exact shape:
{
  "facts": ["short bullet restating a key fact from the description", ...],
  "timeline": [
    {"event_date": "YYYY-MM-DD or null if no date is mentioned", "description": "what happened, in one line"}
  ],
  "statutes": [
    {"citation": "BNS Section 103", "oldCitation": "IPC Section 302", "title": "Murder", "explanation": "one plain-English line", "confidence": "high|medium|low"}
  ],
  "steps": ["concrete next step, e.g. which forum or authority to approach", ...],
  "disclaimer": "This is legal information, not legal advice — consult a licensed advocate for your specific case."
}
For "timeline": extract every date-anchored event mentioned in the case description, in chronological order. If the description mentions an event but no explicit date, still include it with event_date null rather than guessing a date. If truly nothing date-like is mentioned, return an empty array.
If nothing in the candidate list fits, return an empty statutes array and say so in a step instead of guessing.${languageLine}

Candidate sections (only cite from this list):
${groundingBlock || "(no strong candidates found in the local dataset)"}`;

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
        max_tokens: 1600,
        reasoning_effort: "low",
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: safeCaseText },
        ],
      }),
    });

    if (!groqRes.ok) {
      const body = await groqRes.text().catch(() => "");
      return res.status(502).json({ error: `Groq API error ${groqRes.status}: ${body.slice(0, 300)}` });
    }

    const data = await groqRes.json();
    const text = data?.choices?.[0]?.message?.content ?? "No response generated.";
    return res.status(200).json({ result: text });
  } catch (err) {
    return res.status(500).json({ error: err instanceof Error ? err.message : "Unknown server error." });
  }
}
