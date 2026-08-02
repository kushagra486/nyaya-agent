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

  const { caseContext, history, agentType } = req.body || {};
  if (!Array.isArray(history) || history.length === 0) {
    return res.status(400).json({ error: "history (array of {role, content}) is required." });
  }

  const safeHistory = history.slice(-MAX_HISTORY).map((m) => ({
    role: m.role === "assistant" ? "assistant" : "user",
    content: String(m.content || "").slice(0, MAX_MESSAGE_CHARS),
  }));

  const safeContext = String(caseContext || "").slice(0, 1500);
  const agent = ["research", "drafting", "compliance"].includes(agentType) ? agentType : "research";

  const AGENT_PROMPTS = {
    research: `You are the Research Agent for Indian law (BNS/BNSS/BSA and their IPC/CrPC/Evidence Act predecessors), continuing a conversation about a specific case.
Case context: ${safeContext}
Focus on: identifying relevant statutes, constitutional provisions, and the general shape of precedent that would apply (without inventing specific case citations you cannot verify).
Never invent a statute section number — if unsure, say so plainly.
Keep answers focused and practical. End every response with a short reminder that this is legal information, not legal advice.`,

    drafting: `You are the Drafting Agent for Indian law, helping structure a legal document for this case (a legal notice, a complaint outline, or similar) — never a court-filed petition itself, and never something the user should submit without a licensed advocate reviewing it first.
Case context: ${safeContext}
When asked to draft something, produce a clearly structured document: heading, parties, statement of facts, the specific ask/relief sought, and a closing. Use formal but plain Indian legal-letter conventions. Use placeholders like [Your Name] / [Date] / [Opposing Party] where specifics aren't known.
Never invent a statute section number. Always end with: "This is a draft for your review and a licensed advocate's signature — it has not been filed and should not be submitted as-is."`,

    compliance: `You are the Compliance Agent for Indian law, specifically checking that legal references in this conversation are current.
Case context: ${safeContext}
Your job: cross-check any statute reference (yours or the user's) against whether it's the CURRENT law. India replaced the IPC/CrPC/Evidence Act with the BNS/BNSS/BSA effective 1 July 2024. If a message cites an old-code section (e.g. "IPC 302", "Section 420", "CrPC 154"), flag it explicitly and give the current BNS/BNSS/BSA equivalent if you can identify it with confidence; if you cannot map it confidently, say so rather than guessing.
Never invent a statute section number. Keep responses short and focused specifically on currency/compliance of citations, not general case strategy.
End every response with a short reminder that this is legal information, not legal advice.`,
  };

  const systemPrompt = AGENT_PROMPTS[agent];

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
