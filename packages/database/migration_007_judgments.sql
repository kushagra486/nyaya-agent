-- Nyaya-Agent :: Migration 007 - Structured Judgments (OpenNyAI)
-- Run this in Supabase SQL Editor (after prior migrations).
--
-- Populated by a Python script (scripts/process_judgments.py) run on a
-- schedule via .github/workflows/opennyai-process.yml - not by the
-- frontend or any Vercel function, since OpenNyAI needs a Python 3.8-3.10
-- runtime with spaCy/transformer models, which doesn't fit Vercel's Node
-- serverless functions.

create table if not exists public.judgments (
  id uuid primary key default gen_random_uuid(),
  source_url text not null unique,
  title text,
  court text,
  summary text,
  rhetorical_roles jsonb default '[]'::jsonb,
  entities jsonb default '[]'::jsonb,
  statutes jsonb default '[]'::jsonb,
  processed_at timestamptz default now()
);

alter table public.judgments enable row level security;

-- Public content (structured summaries of public judgments), same
-- tradeoff as pulse_items: public read, and public insert since the
-- processing script runs with no user session and this project never
-- uses a service_role key anywhere.
drop policy if exists "judgments_public_read" on public.judgments;
create policy "judgments_public_read" on public.judgments
  for select using (true);

drop policy if exists "judgments_public_insert" on public.judgments;
create policy "judgments_public_insert" on public.judgments
  for insert with check (true);

create index if not exists judgments_processed_at_idx on public.judgments (processed_at desc);
