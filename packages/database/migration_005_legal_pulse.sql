-- Nyaya-Agent :: Migration 005 - Legal Pulse (RSS aggregation)
-- Run this in Supabase SQL Editor (after prior migrations).
--
-- This starts with RSS ingestion only, per the spec's own suggested build
-- order ("start with RSS ingestion only, add eCourts + OpenNyAI structuring
-- in a second pass") - eCourts scraping and OpenNyAI structuring are
-- separate, larger follow-up work (the former needs careful rate-limit
-- handling against a real government portal; the latter needs a Python ML
-- runtime that doesn't fit Vercel's Node serverless functions).

create table if not exists public.pulse_items (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('livelaw', 'barandbench', 'sccblog')),
  external_id text not null,
  title text not null,
  summary text,
  url text not null,
  published_at timestamptz,
  created_at timestamptz default now(),
  unique (source, external_id)
);

alter table public.pulse_items enable row level security;

-- This is public news aggregation content, not user data - anyone (incl.
-- anonymous sessions) can read it.
drop policy if exists "pulse_items_public_read" on public.pulse_items;
create policy "pulse_items_public_read" on public.pulse_items
  for select using (true);

-- The ingestion endpoint runs as a normal anon-key client (no service_role
-- key is used anywhere in this project), so it needs INSERT permission too.
-- Tradeoff: any anon-key holder could technically write rows here. Given
-- this table only ever holds public news-feed content (never sensitive
-- data), that's an acceptable tradeoff for a zero-cost stack; a production
-- deployment would instead run ingestion with a service_role key or a
-- dedicated signed-secret endpoint.
drop policy if exists "pulse_items_public_insert" on public.pulse_items;
create policy "pulse_items_public_insert" on public.pulse_items
  for insert with check (true);

create index if not exists pulse_items_published_at_idx on public.pulse_items (published_at desc);
create index if not exists pulse_items_source_idx on public.pulse_items (source);
