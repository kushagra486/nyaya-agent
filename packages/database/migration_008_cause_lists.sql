-- Nyaya-Agent :: Migration 008 - eCourts Cause Lists
-- Run this in Supabase SQL Editor (after prior migrations).
--
-- Populated by scripts/fetch_cause_lists.py via a scheduled GitHub Actions
-- workflow (.github/workflows/ecourts-causelists.yml), using the real
-- openjustice-in/ecourts library (PyPI package name: `ecourts`) - the one
-- named in the original spec. That library implements genuine automated
-- CAPTCHA solving (OpenCV preprocessing + Tesseract OCR tuned to eCourts'
-- specific CAPTCHA format), not a "pause for a human" workaround.
--
-- Scope: this covers "Get Cause List" specifically, since that's the one
-- operation the library's own docs mark as fully supported (not
-- work-in-progress) - case-number/party-name lookup are still WIP in the
-- upstream library as of when this was built.

create table if not exists public.cause_lists (
  id uuid primary key default gen_random_uuid(),
  state_code text not null,
  court_code text,
  court_name text,
  cause_list_date date not null,
  bench text,
  list_type text,
  causelist_id text,
  document_url text,
  video_conferencing boolean default false,
  fetched_at timestamptz default now(),
  unique (state_code, court_code, cause_list_date, causelist_id)
);

alter table public.cause_lists enable row level security;

-- Public content (published court cause lists), same tradeoff as
-- pulse_items/judgments: public read/insert, no service_role key used
-- anywhere in this project.
drop policy if exists "cause_lists_public_read" on public.cause_lists;
create policy "cause_lists_public_read" on public.cause_lists
  for select using (true);

drop policy if exists "cause_lists_public_insert" on public.cause_lists;
create policy "cause_lists_public_insert" on public.cause_lists
  for insert with check (true);

create index if not exists cause_lists_date_idx on public.cause_lists (cause_list_date desc);
