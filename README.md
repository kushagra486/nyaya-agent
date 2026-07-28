# Nyaya-Agent

Open-source, privacy-first legal intelligence tools for the Indian legal
transition — IPC → BNS, CrPC → BNSS, Indian Evidence Act → BSA.

**Live app:** https://kushagra486.github.io/nyaya-agent/

## What's here

```
nyaya-agent/
├── apps/web/              # Vite + React + TypeScript web app (deployed to GitHub Pages)
├── packages/legal-data/   # Ingestion pipeline: bare-act mapping CSVs → Supabase pgvector
└── .github/workflows/     # CI/CD — auto-deploys apps/web on every push to main
```

### apps/web — the web app

A single-page app with three tools:

1. **Section Correlator** — type any old or new section number (IPC/CrPC/Evidence
   Act ↔ BNS/BNSS/BSA) and get an instant cross-reference.
2. **Statute Matching** — describe a situation in plain language; the app scores
   it against the local mapping dataset for candidate sections, then asks Groq's
   free Llama 3.3 70B to explain the likely current-law citations — grounded
   only in sections it actually found, never invented.
3. **Full Register** — browse and filter every mapped section.

**Zero-cost by design:** static site, no backend, no database for the web app
itself. Each visitor supplies their own free Groq API key (console.groq.com/keys),
which is stored only in their browser's localStorage and sent only to
`api.groq.com` — never bundled into the build, never committed to this repo.

Run locally:

```bash
cd apps/web
npm install
npm run dev
```

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
