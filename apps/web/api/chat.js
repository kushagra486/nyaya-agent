// Multi-turn chat proxy — same server-side GROQ_API_KEY as api/analyze.js,
// but accepts a running message history instead of a single case description.

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const MODEL = "llama-3.3-70b-versatile";
const MAX_MESSAGE_CHARS = 1500;
const MAX_HISTORY = 12;

const hits = new Map();
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 12;

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

  const { caseContext, history } = req.body || {};
  if (!Array.isArray(history) || history.length === 0) {
    return res.status(400).json({ error: "history (array of {role, content}) is required." });
  }

  const safeHistory = history.slice(-MAX_HISTORY).map((m) => ({
    role: m.role === "assistant" ? "assistant" : "user",
    content: String(m.content || "").slice(0, MAX_MESSAGE_CHARS),
  }));

  const systemPrompt = `You are a legal-information assistant for Indian law (BNS/BNSS/BSA and their IPC/CrPC/Evidence Act predecessors), continuing a conversation about a specific case.
Case context: ${String(caseContext || "").slice(0, 1500)}
Never invent a statute section number — if unsure, say so plainly.
Keep answers focused and practical. End every response with a short reminder that this is legal information, not legal advice.`;

  try {
    const groqRes = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 0.3,
        max_tokens: 700,
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
