# Nyaya-Agent — Legal Knowledge Base Ingestion

Zero-cost ingestion pipeline for the Indian bare-act cross-mapping RAG layer
(IPC ↔ BNS, CrPC ↔ BNSS, Evidence Act ↔ BSA).

**Stack:** Supabase (free tier, pgvector) + local `sentence-transformers`
embeddings (no API key, runs on CPU) + Groq (wired for the downstream
chat/analysis agents in later phases).

## What's in here

```
legal-data/
├── data/
│   ├── ipc_bns_mapping.csv        # 65 verified section mappings (IPC->BNS)
│   ├── crpc_bnss_mapping.csv      # 28 verified section mappings (CrPC->BNSS)
│   └── evidence_bsa_mapping.csv   # 14 verified section mappings (Evidence Act->BSA)
├── supabase_schema.sql            # pgvector tables + match_statutes() RPC
├── ingest_bare_acts.py            # main pipeline
├── requirements.txt
└── .env.example
```

Each CSV row becomes one retrieval chunk that mentions **both** the old and
new section number and offence title, so a query in either vocabulary
("IPC 302" or "BNS 103") hits the same record — this is the
`bns_mapped_section` cross-mapping the original spec calls for.

**Verified against current sources (July 2026):** the mappings were checked
against live legal-reference sites rather than pulled from memory, since BNS/BNSS/BSA
are 2023–2024 laws. That said, treat the seed set as a **starting scaffold, not
a complete bare act** — it currently covers the most commonly cited ~100
sections. The full BNS has 358 sections, BNSS has 531, BSA has 170.

## 1. Set up Supabase (free tier)

1. Create a project at supabase.com (free tier is enough for this).
2. Open the SQL Editor → paste and run `supabase_schema.sql`.
3. Copy your Project URL and `service_role` key (Settings → API) into `.env`
   (copy `.env.example` → `.env` first — never commit `.env`).

## 2. Install & run

```bash
cd packages/legal-data
pip install -r requirements.txt --break-system-packages   # if outside a venv

# Dry run first — embeds locally, prints a sample record, no DB writes
python ingest_bare_acts.py --dry-run

# Real run — embeds + upserts into Supabase statutes_index
python ingest_bare_acts.py --target-db supabase
```

First run downloads the `all-MiniLM-L6-v2` model (~90MB) once; it's cached
locally after that, so re-runs are fast and fully offline for embedding.

## 3. Verify + query (hard-RAG threshold check)

In the Supabase SQL editor, once you have an embedding for a test query
(generate it the same way the pipeline does — same model, same dimension):

```sql
select * from match_statutes(
  query_embedding := '[...]'::vector,
  match_threshold := 0.75,
  match_count := 5
);
```

Anything below the 0.75 cosine-similarity threshold is intentionally
excluded — this is the "Hard-RAG policy" from the compliance matrix (section 6
of the original spec): the model should decline to answer rather than
hallucinate a statute when retrieval confidence is low.

## Next steps (not built yet)

- **Expand the CSVs** to the full bare acts (358/531/170 sections) — either by
  manually transcribing from the official Gazette PDFs, or wiring in an
  OCR/PDF-parsing step once you have the official texts on hand. This
  pipeline's `load_rows()` function is the seam to extend — add new source
  files to the `SOURCES` list and it flows straight through.
- `judgments_index` ingestion (Supreme Court/HC precedents) — schema exists,
  script doesn't yet.
- Groq-backed chat/analysis agents that call `match_statutes()` and enforce
  the citation + disclaimer guardrails from the spec.
- GitHub Actions workflow to re-run ingestion on every CSV change (happy to
  wire this into your existing GitHub activity automation under kushagra486
  when you're ready).
