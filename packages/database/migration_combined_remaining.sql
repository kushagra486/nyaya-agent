-- Nyaya-Agent :: Combined migration (everything currently missing)
-- Based on your Supabase Table Editor screenshot: profiles, cases,
-- messages, lawyers, consultations, client_status_links already exist
-- (migration_003 was already applied). This file combines everything
-- still missing: migrations 002, 004, 005, 006, 007, 008.
--
-- Safe to run as one script - every statement uses IF NOT EXISTS /
-- CREATE OR REPLACE / DROP POLICY IF EXISTS, so nothing breaks even if a
-- piece partially exists already. Paste this whole file into Supabase's
-- SQL Editor and click Run once.


-- ============================================================
-- Migration 002 - Case Timeline
-- ============================================================

-- Nyaya-Agent :: Migration 002 - Case Timeline
-- Run this in Supabase SQL Editor (after schema.sql has already been run).
-- Implements item #1 from the backend spec: "Case Timeline — auto-chronology
-- per case, derived from extracted facts."

create table if not exists public.timeline_events (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  event_date date,
  description text not null,
  source text not null default 'user' check (source in ('user', 'ai', 'court_feed')),
  created_at timestamptz default now()
);

alter table public.timeline_events enable row level security;

drop policy if exists "timeline_events_owner_all" on public.timeline_events;
create policy "timeline_events_owner_all" on public.timeline_events
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists timeline_events_case_id_idx on public.timeline_events (case_id, event_date);

-- ============================================================
-- Migration 004 - Document Vault
-- ============================================================

-- Nyaya-Agent :: Migration 004 - Document Vault + clause-level AI review
-- Run this in Supabase SQL Editor (after schema.sql, migration_002, migration_003).

-- ============================================================
-- 1. Storage bucket for uploaded documents (private - not public)
-- ============================================================
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

-- Users can only read/write files under a path prefixed with their own
-- user id (documents/{user_id}/{filename}), enforced via storage RLS.
drop policy if exists "documents_bucket_owner_read" on storage.objects;
create policy "documents_bucket_owner_read" on storage.objects
  for select using (bucket_id = 'documents' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "documents_bucket_owner_insert" on storage.objects;
create policy "documents_bucket_owner_insert" on storage.objects
  for insert with check (bucket_id = 'documents' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "documents_bucket_owner_delete" on storage.objects;
create policy "documents_bucket_owner_delete" on storage.objects
  for delete using (bucket_id = 'documents' and auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================
-- 2. Documents + clause review
-- ============================================================
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  filename text not null,
  storage_path text not null,
  mime_type text,
  status text not null default 'queued' check (status in ('queued', 'reviewed', 'failed')),
  uploaded_at timestamptz default now()
);

alter table public.documents enable row level security;

drop policy if exists "documents_owner_all" on public.documents;
create policy "documents_owner_all" on public.documents
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create index if not exists documents_case_id_idx on public.documents (case_id);

create table if not exists public.document_clauses (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.documents(id) on delete cascade,
  clause_order int not null default 0,
  clause_text text not null,
  risk_level text not null default 'low' check (risk_level in ('low', 'medium', 'high')),
  ai_explanation text,
  created_at timestamptz default now()
);

alter table public.document_clauses enable row level security;

-- Clause rows are readable/writable only via the parent document's owner
drop policy if exists "document_clauses_owner_all" on public.document_clauses;
create policy "document_clauses_owner_all" on public.document_clauses
  for all using (
    exists (select 1 from public.documents d where d.id = document_id and d.owner_id = auth.uid())
  ) with check (
    exists (select 1 from public.documents d where d.id = document_id and d.owner_id = auth.uid())
  );

create index if not exists document_clauses_document_id_idx on public.document_clauses (document_id, clause_order);

-- ============================================================
-- Migration 005 - Legal Pulse
-- ============================================================

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

-- ============================================================
-- Migration 006 - Hearing Reminders
-- ============================================================

-- Nyaya-Agent :: Migration 006 - Hearing Reminders (email only)
-- Run this in Supabase SQL Editor (after prior migrations).

-- ============================================================
-- 1. Hearing date on cases (closes the loop on the dashboard's
--    "Next hearing" placeholder that's been there since the earliest UI)
-- ============================================================
alter table public.cases
  add column if not exists next_hearing_date timestamptz;

-- ============================================================
-- 2. Copy email onto profiles - the reminder-sending cron job runs with
--    no specific user's session (it's a scheduled job, not a logged-in
--    visitor), and this project never uses the service_role key, so it
--    has no way to read auth.users directly. Denormalizing email onto
--    profiles (readable via the security-definer RPC below) solves this
--    without needing that key anywhere.
-- ============================================================
alter table public.profiles
  add column if not exists email text;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, new.raw_user_meta_data ->> 'full_name', new.email);
  return new;
end;
$$;
-- (trigger itself already exists from schema.sql and points at this
-- function by name, so re-creating the function is enough - no need to
-- re-create the trigger.)

-- Backfill email for any profiles created before this migration
update public.profiles p
set email = u.email
from auth.users u
where p.id = u.id and p.email is null;

-- ============================================================
-- 3. Reminders (email only per current scope - push/SMS not wired)
-- ============================================================
create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  remind_at timestamptz not null,
  sent boolean not null default false,
  created_at timestamptz default now()
);

alter table public.reminders enable row level security;

drop policy if exists "reminders_owner_all" on public.reminders;
create policy "reminders_owner_all" on public.reminders
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists reminders_due_idx on public.reminders (remind_at) where sent = false;

-- ============================================================
-- 4. Security-definer RPCs for the cron job (same pattern as
--    get_case_status_by_token - lets an unauthenticated scheduled job
--    do a narrow, controlled thing without a service_role key)
-- ============================================================
create or replace function public.get_due_reminders()
returns table (
  reminder_id uuid,
  case_title text,
  recipient_email text,
  remind_at timestamptz
)
language plpgsql
security definer set search_path = public
as $$
begin
  return query
    select r.id, c.title, p.email, r.remind_at
    from public.reminders r
    join public.cases c on c.id = r.case_id
    join public.profiles p on p.id = r.user_id
    where r.sent = false
      and r.remind_at <= now()
      and p.email is not null;
end;
$$;

grant execute on function public.get_due_reminders() to anon, authenticated;

create or replace function public.mark_reminder_sent(p_reminder_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update public.reminders set sent = true where id = p_reminder_id;
end;
$$;

grant execute on function public.mark_reminder_sent(uuid) to anon, authenticated;

-- ============================================================
-- Migration 007 - Structured Judgments
-- ============================================================

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

-- ============================================================
-- Migration 008 - eCourts Cause Lists
-- ============================================================

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
