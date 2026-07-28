# Nyaya-Agent

Open-source, privacy-first legal intelligence tools for the Indian legal
transition — IPC → BNS, CrPC → BNSS, Indian Evidence Act → BSA.

**Live app (full functionality, incl. AI statute matching):** deployed on Vercel — see repo "About" link once deployed.
**Static mirror (Section Correlator + Full Register only):** https://kushagra486.github.io/nyaya-agent/

## What's here

```
nyaya-agent/
├── apps/web/              # Vite + React + TypeScript web app
│   └── api/analyze.js     # Vercel serverless function — holds the Groq key server-side
├── packages/legal-data/   # Ingestion pipeline: bare-act mapping CSVs → Supabase pgvector
└── .github/workflows/     # CI/CD — auto-deploys the static build to GitHub Pages
```

### apps/web — the web app

A single-page app with three tools:

1. **Section Correlator** — type any old or new section number (IPC/CrPC/Evidence
   Act ↔ BNS/BNSS/BSA) and get an instant cross-reference. Pure client-side.
2. **Statute Matching** — describe a situation in plain language; the app scores
   it against the local mapping dataset for candidate sections, then calls
   `/api/analyze` (a Vercel serverless function) which asks Llama 3.3 70B via
   Groq to explain the likely current-law citations — grounded only in
   sections it actually found, never invented.
3. **Full Register** — browse and filter every mapped section. Pure client-side.

**Key handling:** the Groq API key is a server-side environment variable in the
Vercel project (`GROQ_API_KEY`) — it is never written into source, never
bundled into the frontend, and never sent to the browser. Visitors don't need
their own key. This means Statute Matching only works on the Vercel
deployment; the GitHub Pages mirror is static-only, so that one tool won't
respond there (Section Correlator and Full Register work everywhere).

Because the key is shared across all visitors, `api/analyze.js` includes a
best-effort per-IP rate limit (resets on cold start — a speed bump, not a
substitute for a real limiter like Upstash/Vercel KV if traffic grows) and
caps input length and response tokens. Consider enabling Vercel's built-in Bot
Protection on this project for extra safety.

Run locally:

```bash
cd apps/web
npm install
npm run dev
```
The `/api/analyze` route needs `vercel dev` (not plain `vite dev`) to run
locally with the serverless function, or use `vercel env pull` after linking
the project.

### packages/legal-data — knowledge base ingestion

A separate, optional pipeline for building a real vector-search RAG backend
(Supabase pgvector + local embeddings) on top of the same mapping data, for
anyone extending this into the fuller multi-agent platform described in the
original spec. See `packages/legal-data/README.md`.

## Disclaimer

Nyaya-Agent provides legal information based on Indian statutes. It is **not**
a substitute for professional legal advice. Always consult a licensed advocate
for your specific situation.

## Contributing

The current dataset covers ~100 of the most commonly cited sections across
BNS (358 total), BNSS (531 total), and BSA (170 total). PRs adding verified
mappings to the CSVs in `packages/legal-data/data/` are welcome — please cite
the source (Gazette notification, bare act, or a reputable legal reference)
in the PR description.

## License

MIT — see [LICENSE](./LICENSE).
