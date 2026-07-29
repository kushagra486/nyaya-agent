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
