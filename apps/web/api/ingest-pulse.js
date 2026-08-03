// Legal Pulse :: RSS ingestion
// Fetches legal-news RSS feeds and upserts new items into pulse_items.
// Meant to be called on a schedule (see .github/workflows/pulse-ingest.yml)
// rather than per-visitor - it's a write operation, not something the
// frontend calls directly.
//
// Feed URLs: LiveLaw's is verified working (https://www.livelaw.in/feed).
// SCC Online Blog follows the standard WordPress /feed convention. Bar &
// Bench's exact feed URL wasn't fully verifiable at build time (their site
// uses a custom CMS) - if it 404s, check https://www.barandbench.com for
// their current feed path and update FEEDS below; each feed is fetched
// independently so one failing doesn't block the others.

import Parser from "rss-parser";

const parser = new Parser();

const FEEDS = [
  { source: "livelaw", url: "https://www.livelaw.in/feed" },
  { source: "sccblog", url: "https://www.scconline.com/blog/feed/" },
  { source: "barandbench", url: "https://www.barandbench.com/feed" },
];

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") return res.status(204).end();

  // Simple shared-secret check so this isn't wide open to the public
  // internet as a write endpoint - set INGEST_SECRET in Vercel env vars
  // and pass the same value from the GitHub Actions workflow.
  const providedSecret = req.headers["x-ingest-secret"] || req.query?.secret;
  if (process.env.INGEST_SECRET && providedSecret !== process.env.INGEST_SECRET) {
    return res.status(401).json({ error: "Invalid or missing ingest secret." });
  }

  const supabaseUrl = "https://qojdhatypfuakhkkedar.supabase.co";
  const supabaseAnonKey = "sb_publishable_OX6lgIfO3vfeDsonPJnDuw_SpipH8_R";

  const results = [];

  for (const feed of FEEDS) {
    try {
      const parsed = await parser.parseURL(feed.url);
      const rows = (parsed.items || []).slice(0, 30).map((item) => ({
        source: feed.source,
        external_id: item.guid || item.link || item.title,
        title: (item.title || "").slice(0, 500),
        summary: (item.contentSnippet || item.content || "").slice(0, 800),
        url: item.link || "",
        published_at: item.isoDate || item.pubDate || null,
      }));

      if (rows.length > 0) {
        const upsertRes = await fetch(`${supabaseUrl}/rest/v1/pulse_items?on_conflict=source,external_id`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            apikey: supabaseAnonKey,
            Authorization: `Bearer ${supabaseAnonKey}`,
            Prefer: "resolution=ignore-duplicates",
          },
          body: JSON.stringify(rows),
        });
        if (!upsertRes.ok) {
          const body = await upsertRes.text().catch(() => "");
          results.push({ source: feed.source, ok: false, error: `Supabase upsert ${upsertRes.status}: ${body.slice(0, 200)}` });
          continue;
        }
      }
      results.push({ source: feed.source, ok: true, itemsFetched: rows.length });
    } catch (err) {
      results.push({ source: feed.source, ok: false, error: err instanceof Error ? err.message : "Unknown error" });
    }
  }

  return res.status(200).json({ results });
}
