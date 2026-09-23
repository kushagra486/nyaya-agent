// Lawyer Chat :: AI-simulated lawyer reply proxy
// Same server-side GROQ_API_KEY pattern as api/chat.js and api/analyze.js.
//
// IMPORTANT: there is no real onboarded lawyer behind this. The frontend
// must always show a persistent disclosure that replies are AI-generated
// under the lawyer profile's name for demo purposes - this endpoint does
// not change that requirement, it just generates the reply text.

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const MODEL = "openai/gpt-oss-120b";
const MAX_MESSAGE_CHARS = 1500;
const MAX_HISTORY = 12;

const hits = new Map();
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 10;

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

  const { lawyerName, specializations, experienceYears, city, caseContext, history, locale } = req.body || {};
  if (!Array.isArray(history) || history.length === 0) {
    return res.status(400).json({ error: "history (array of {role, content}) is required." });
  }

  const safeHistory = history.slice(-MAX_HISTORY).map((m) => ({
    role: m.role === "lawyer" ? "assistant" : "user",
    content: String(m.content || "").slice(0, MAX_MESSAGE_CHARS),
  }));

  const specList = Array.isArray(specializations) ? specializations.join(", ") : "general practice";
  const safeContext = String(caseContext || "").slice(0, 1200);

  const LOCALE_NAMES = { hi: "Hindi", mr: "Marathi", ta: "Tamil", en: "English" };
  const languageName = LOCALE_NAMES[locale] || "English";
  const languageLine = languageName === "English" ? "" : `\nRespond natively in ${languageName} (not transliterated English).`;

  const systemPrompt = `You are role-playing as ${lawyerName || "an advocate"}, a practicing Indian advocate specializing in ${specList}, based in ${city || "India"}, with ${experienceYears || "several"} years of experience.
Respond warmly, professionally, and like a real lawyer having an initial conversation with a prospective client - ask clarifying questions, give general preliminary guidance, and reference relevant areas of law where appropriate.
${safeContext ? `The client's case context so far: ${safeContext}` : ""}
Hard rules:
- Never invent a statute section number you're not confident about.
- Never claim to have filed anything, taken formal legal action, or made commitments on the client's behalf - this is a chat conversation, not representation.
- For anything requiring a signature, court filing, or formal opinion, say this needs a proper consultation (in person or scheduled call) rather than doing it over chat.
- Keep responses conversational and not overly long - this is a chat, not a legal memo.${languageLine}`;

  try {
    const groqRes = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 0.4,
        max_tokens: 900,
        reasoning_effort: "low",
        messages: [{ role: "system", content: systemPrompt }, ...safeHistory],
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
