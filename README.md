# Nyaya-Agent

Open-source, privacy-first legal intelligence tools for the Indian legal
transition — IPC → BNS, CrPC → BNSS, Indian Evidence Act → BSA.

**Live app (full functionality, incl. AI statute matching):** deployed on Vercel — see repo "About" link once deployed.
**Static mirror:** https://kushagra486.github.io/nyaya-agent/ (note: Statute Matching/Chat/Lawyer-booking need `/api/*`, which only exists on the Vercel deployment — see below)

## What's here

```
nyaya-agent/
├── apps/web/              # Single-file static frontend (index.html) + Vercel serverless functions
│   ├── index.html         # The whole app: Dashboard, AI Legal Analysis, Chat, Lawyers, History, Library, Profile
│   ├── api/analyze.js     # Vercel serverless function — holds the Groq key server-side
│   └── api/chat.js        # Multi-turn chat proxy, same key handling
├── apps/mobile/           # Flutter mobile app (Android/iOS) — same Supabase + same Vercel API
├── packages/legal-data/   # Ingestion pipeline: bare-act mapping CSVs → Supabase pgvector
├── packages/database/     # schema.sql for the app backend (profiles/cases/messages/lawyers/consultations)
└── .github/workflows/     # CI/CD — auto-deploys the static build to GitHub Pages
```

### apps/web — the web app

A single self-contained `index.html` (no build step needed — Vite just passes
it through unchanged) implementing the full product:

1. **Auth** — email/password + magic link, gates everything below it.
2. **Dashboard** — real cases from Supabase, "+ New Case" intake, status pills.
3. **AI Legal Analysis** — per-case, calls `/api/analyze`, saves structured
   facts/statutes/steps JSON back to the case row. Statute chips open a
   bottom-sheet with the real citation explanation.
4. **Chat with Agent** — multi-turn, persisted to the `messages` table, calls
   `/api/chat` with running history + case context.
5. **Find a Lawyer** — real directory from Supabase, specialization filter
   pills, consultation requests written to `consultations`.
6. **Case History** — every case, read-only list.
7. **Legal Library** — searchable table of all 107 IPC/CrPC/Evidence Act ↔
   BNS/BNSS/BSA mappings, embedded inline (no fetch needed).
8. **Profile** — account email + sign out.

**Key handling:** the Groq API key is a server-side environment variable in the
Vercel project (`GROQ_API_KEY`) — it is never written into source, never
bundled into the frontend, and never sent to the browser. Visitors don't need
their own key. This means Analysis/Chat/Lawyer-booking only fully work on the
Vercel deployment; the GitHub Pages mirror is static-only, so those calls will
error there (Supabase-backed features like Dashboard/Auth still work anywhere,
since Supabase is called directly from the browser via its own client library).

Because the key is shared across all visitors, `api/analyze.js` and
`api/chat.js` include a best-effort per-IP rate limit (resets on cold start —
a speed bump, not a substitute for a real limiter like Upstash/Vercel KV if
traffic grows) and cap input length and response tokens. Consider enabling
Vercel's built-in Bot Protection on this project for extra safety.

Run locally: just open `apps/web/index.html` in a browser, or `cd apps/web && vercel dev`
if you want `/api/*` working locally too (plain `vite dev`/`npm run dev` won't
run the serverless functions).

### apps/mobile — the Flutter mobile app

Native Android/iOS implementation of the same product (Dashboard, AI Legal
Analysis, Chat, Verify & Book Lawyer), sharing the exact same backend as the
web app — same Supabase project/tables/RLS, same Vercel `/api/analyze` and
`/api/chat` endpoints (so the Groq key story is identical: server-side only,
never in the app bundle). See `apps/mobile/README.md` for the one-time
`flutter create .` step needed to generate platform folders, since those
aren't committed here.

### packages/legal-data — knowledge base ingestion

A separate, optional pipeline for building a real vector-search RAG backend
(Supabase pgvector + local embeddings) on top of the same mapping data, for
anyone extending this into the fuller multi-agent platform described in the
original spec. See `packages/legal-data/README.md`.

## Disclaimer

Nyaya-Agent provides legal information based on Indian statutes. It is **not**
a substitute for professional legal advice. Always consult a licensed advocate
for your specific situation.

## Versioning

The live site is always the latest version. Full history of what changed and
why is in [CHANGELOG.md](./CHANGELOG.md). Past frontend snapshots are kept
browsable at `apps/web/versions/` (open any `.html` file directly — they're
self-contained, no build step). Each release is also tagged in git
(`git tag`), so `git checkout v0.5.0` gets you the exact commit for that
version.

## Contributing

The current dataset covers ~100 of the most commonly cited sections across
BNS (358 total), BNSS (531 total), and BSA (170 total). PRs adding verified
mappings to the CSVs in `packages/legal-data/data/` are welcome — please cite
the source (Gazette notification, bare act, or a reputable legal reference)
in the PR description.

## License

MIT — see [LICENSE](./LICENSE).
