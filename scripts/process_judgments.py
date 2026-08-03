#!/usr/bin/env python3
"""
Nyaya-Agent :: Legal Pulse judgment structuring (OpenNyAI)

Runs OpenNyAI's three pretrained models (NER, Rhetorical Role
classification, Extractive Summarization) on judgment texts and pushes
structured results to Supabase's `judgments` table.

IMPORTANT - honesty about what's verified vs not:
This script was written from OpenNyAI's documented usage pattern
(https://github.com/OpenNyAI/Opennyai, https://opennyai.readthedocs.io/)
but could NOT be test-run in the environment this was built in - the
opennyai package requires Python 3.8-3.10 with an older spaCy/thinc/Cython
toolchain, and that environment only had Python 3.12 available (pip install
opennyai failed there with a Cython build error, confirming the version
mismatch). This is the one piece in the whole project that hasn't been
run end-to-end before shipping. The exact shape of Pipeline()'s return
value (`result` below) is a best-effort reconstruction from partial
documentation - if this errors on first real run, print(result) /
print(dir(result)) right after the pipeline call to see its actual
structure, and adjust the extraction code below accordingly.

Requires: Python 3.10 (see .github/workflows/opennyai-process.yml)
"""

import json
import os
import sys
import urllib.request

import requests

SUPABASE_URL = "https://qojdhatypfuakhkkedar.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_OX6lgIfO3vfeDsonPJnDuw_SpipH8_R"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCES_FILE = os.path.join(SCRIPT_DIR, "judgment_sources.txt")


def load_sources():
    with open(SOURCES_FILE, "r", encoding="utf-8") as f:
        lines = [ln.strip() for ln in f]
    return [ln for ln in lines if ln and not ln.startswith("#")]


def already_processed(url):
    """Check whether this source_url is already in the judgments table."""
    resp = requests.get(
        f"{SUPABASE_URL}/rest/v1/judgments",
        params={"source_url": f"eq.{url}", "select": "id"},
        headers={"apikey": SUPABASE_ANON_KEY, "Authorization": f"Bearer {SUPABASE_ANON_KEY}"},
        timeout=15,
    )
    return resp.ok and len(resp.json()) > 0


def fetch_text(url):
    """Fetch judgment text. Plain .txt URLs are used as-is; Indian Kanoon
    /doc/ pages are HTML and need text extraction - this uses a best-effort
    BeautifulSoup selector that has NOT been verified against a live
    Indian Kanoon page (indiankanoon.org isn't reachable from the sandbox
    this was built in). Check the actual page structure and adjust the
    selector below if extraction comes back empty or garbled."""
    if url.rstrip("/").endswith(".txt") or "raw.githubusercontent.com" in url:
        with urllib.request.urlopen(url, timeout=20) as resp:
            return resp.read().decode("utf-8", errors="ignore")

    # Indian Kanoon HTML page - best-effort extraction, unverified.
    from bs4 import BeautifulSoup

    resp = requests.get(url, timeout=20, headers={"User-Agent": "Mozilla/5.0 (compatible; NyayaAgentBot/1.0)"})
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")
    # Indian Kanoon judgment text commonly sits in a div with class
    # "judgments" or "akn-judgment" depending on the page template -
    # trying a few candidates and falling back to the whole <body> text.
    for selector in [{"class_": "judgments"}, {"class_": "akn-judgment"}, {"id": "content"}]:
        container = soup.find("div", **selector)
        if container and container.get_text(strip=True):
            return container.get_text("\n", strip=True)
    return soup.get_text("\n", strip=True)


def extract_title_and_court(text):
    """Very rough heuristic: first non-empty line as title, look for a
    common court-name keyword in the first few lines. Refine once you see
    real extracted text - this is deliberately simple, not a claim of
    accuracy."""
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    title = lines[0][:300] if lines else "Untitled judgment"
    court = "Unknown"
    for ln in lines[:10]:
        for keyword, label in [
            ("supreme court", "Supreme Court of India"),
            ("high court", "High Court"),
            ("district court", "District Court"),
        ]:
            if keyword in ln.lower():
                court = label
                break
    return title, court


def run_opennyai(texts):
    """Run OpenNyAI's 3 models. See the module docstring - this call
    pattern is a best-effort reconstruction and may need adjusting on
    first real run."""
    from opennyai import Pipeline
    from opennyai.utils import Data

    data = Data(texts)
    pipeline = Pipeline(
        components=["Rhetorical_Role", "NER", "Summarizer"],
        use_gpu=False,
        verbose=True,
    )
    result = pipeline(data)

    # DEBUG: uncomment if the shape below doesn't match reality
    # print("RESULT TYPE:", type(result)); print("RESULT:", result)

    return result


def structure_result(raw_text, model_output):
    """Best-effort extraction of entities/roles/summary from the pipeline
    output. Wrapped defensively since the exact return shape wasn't
    verified - adjust field access here once you've seen a real run's
    output shape (see run_opennyai's docstring)."""
    entities, roles, summary = [], [], ""
    try:
        entities = getattr(model_output, "entities", None) or model_output.get("entities", [])
    except Exception:
        pass
    try:
        roles = getattr(model_output, "rhetorical_roles", None) or model_output.get("rhetorical_roles", [])
    except Exception:
        pass
    try:
        summary = getattr(model_output, "summary", None) or model_output.get("summary", "")
    except Exception:
        pass
    return entities, roles, summary


def upsert_judgment(row):
    resp = requests.post(
        f"{SUPABASE_URL}/rest/v1/judgments?on_conflict=source_url",
        headers={
            "Content-Type": "application/json",
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "Prefer": "resolution=merge-duplicates",
        },
        data=json.dumps([row]),
        timeout=20,
    )
    return resp.ok, (resp.text if not resp.ok else "")


def main():
    sources = load_sources()
    print(f"Loaded {len(sources)} judgment source(s).")

    to_process = []
    texts_by_url = {}
    for url in sources:
        if already_processed(url):
            print(f"  skip (already processed): {url}")
            continue
        try:
            text = fetch_text(url)
            if not text or len(text.strip()) < 100:
                print(f"  skip (no usable text extracted): {url}")
                continue
            texts_by_url[url] = text
            to_process.append(url)
        except Exception as e:
            print(f"  ERROR fetching {url}: {e}")

    if not to_process:
        print("Nothing new to process.")
        return

    print(f"Running OpenNyAI on {len(to_process)} judgment(s)...")
    try:
        result = run_opennyai([texts_by_url[u] for u in to_process])
    except Exception as e:
        print(f"FATAL: OpenNyAI pipeline call failed: {e}")
        print("See the module docstring - the Pipeline() call signature may need adjusting.")
        sys.exit(1)

    # result is expected to be iterable, one entry per input text, in the
    # same order as `to_process` - unverified, see docstring.
    outputs = result if hasattr(result, "__iter__") else [result]

    for url, model_output in zip(to_process, outputs):
        text = texts_by_url[url]
        title, court = extract_title_and_court(text)
        entities, roles, summary = structure_result(text, model_output)
        row = {
            "source_url": url,
            "title": title,
            "court": court,
            "summary": summary or text[:500],
            "rhetorical_roles": roles,
            "entities": entities,
            "statutes": [e for e in entities if isinstance(e, dict) and e.get("label") in ("STATUTE", "PROVISION")],
        }
        ok, err = upsert_judgment(row)
        print(f"  {'OK' if ok else 'FAILED'}: {url}" + (f" - {err[:200]}" if err else ""))


if __name__ == "__main__":
    main()
