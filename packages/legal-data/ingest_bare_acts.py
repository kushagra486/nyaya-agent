"""
Nyaya-Agent :: Legal Knowledge Base Ingestion Pipeline
--------------------------------------------------------
Reads the bare-act cross-mapping CSVs (IPC->BNS, CrPC->BNSS, Evidence Act->BSA),
builds a retrieval-ready text chunk per section, embeds it locally (free,
no API key) with sentence-transformers, and upserts into Supabase's
`statutes_index` pgvector table.

Usage:
    python ingest_bare_acts.py --dry-run          # embed + validate, skip Supabase writes
    python ingest_bare_acts.py --target-db supabase

Zero-cost stack: local embeddings (sentence-transformers) + Supabase free tier
pgvector storage. Groq is wired in for the downstream chat/analysis agents,
not needed for ingestion itself since Groq does not currently serve an
embeddings endpoint.
"""
import argparse
import os
import sys
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from tqdm import tqdm

load_dotenv()

DATA_DIR = Path(__file__).parent / "data"

SOURCES = [
    {
        "file": "ipc_bns_mapping.csv",
        "old_act": "IPC 1860",
        "new_act": "BNS 2023",
    },
    {
        "file": "crpc_bnss_mapping.csv",
        "old_act": "CrPC 1973",
        "new_act": "BNSS 2023",
    },
    {
        "file": "evidence_bsa_mapping.csv",
        "old_act": "Indian Evidence Act 1872",
        "new_act": "BSA 2023",
    },
]


def build_chunk_text(row: dict, old_act: str, new_act: str) -> str:
    """Compose a single retrieval chunk covering both the legacy and current code,
    so a query in either vocabulary ('IPC 302' or 'BNS 103') retrieves the same fact."""
    title_key = "offence_title" if "offence_title" in row else "provision_title"
    title = row.get(title_key, "") or ""
    notes = row.get("notes", "") or ""
    return (
        f"{title}. "
        f"Old law: Section {row['old_section']} of the {old_act}. "
        f"Current law: Section {row['new_section']} of the {new_act}. "
        f"{notes}"
    ).strip()


def load_rows():
    rows = []
    for source in SOURCES:
        path = DATA_DIR / source["file"]
        if not path.exists():
            print(f"[skip] {path} not found", file=sys.stderr)
            continue
        df = pd.read_csv(path).fillna("")
        for _, r in df.iterrows():
            r = r.to_dict()
            rows.append(
                {
                    "act_name": source["new_act"],
                    "section_number": str(r["new_section"]),
                    "bns_mapped_section": str(r["old_section"]),
                    "title": r.get("offence_title") or r.get("provision_title") or "",
                    "content": build_chunk_text(r, source["old_act"], source["new_act"]),
                    "enactment_year": 2023,
                    "metadata": {
                        "old_act": source["old_act"],
                        "old_section": str(r["old_section"]),
                    },
                }
            )
    return rows


def embed_rows(rows, model_name: str):
    from sentence_transformers import SentenceTransformer

    print(f"Loading local embedding model: {model_name} (first run downloads ~90MB, then cached)")
    model = SentenceTransformer(model_name)
    texts = [r["content"] for r in rows]
    embeddings = model.encode(texts, show_progress_bar=True, batch_size=32, normalize_embeddings=True)
    for row, vec in zip(rows, embeddings):
        row["embedding"] = vec.tolist()
    return rows


def upsert_to_supabase(rows):
    from supabase import create_client

    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    client = create_client(url, key)

    batch_size = 100
    for i in tqdm(range(0, len(rows), batch_size), desc="Upserting to Supabase"):
        batch = rows[i : i + batch_size]
        client.table("statutes_index").upsert(
            batch, on_conflict="act_name,section_number"
        ).execute()


def main():
    parser = argparse.ArgumentParser(description="Ingest Indian bare-act mappings into the vector DB")
    parser.add_argument("--target-db", choices=["supabase"], default="supabase")
    parser.add_argument("--dry-run", action="store_true", help="Embed and validate only, skip DB writes")
    args = parser.parse_args()

    model_name = os.environ.get("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")

    rows = load_rows()
    print(f"Loaded {len(rows)} statute sections from {len(SOURCES)} source files.")
    if not rows:
        print("No rows loaded - check that data/*.csv files exist.", file=sys.stderr)
        sys.exit(1)

    rows = embed_rows(rows, model_name)
    print(f"Generated embeddings: dim={len(rows[0]['embedding'])} for {len(rows)} sections.")

    if args.dry_run:
        print("\n--dry-run set: skipping Supabase write. Sample record:")
        sample = {k: v for k, v in rows[0].items() if k != "embedding"}
        sample["embedding"] = f"<{len(rows[0]['embedding'])}-dim vector>"
        for k, v in sample.items():
            print(f"  {k}: {v}")
        return

    if "SUPABASE_URL" not in os.environ or "SUPABASE_SERVICE_ROLE_KEY" not in os.environ:
        print("Missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY in .env — copy .env.example to .env first.", file=sys.stderr)
        sys.exit(1)

    upsert_to_supabase(rows)
    print("Done. Run a query against match_statutes() in Supabase to verify.")


if __name__ == "__main__":
    main()
