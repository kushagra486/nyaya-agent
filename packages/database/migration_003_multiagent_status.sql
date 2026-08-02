-- Nyaya-Agent :: Migration 003 - Multi-agent chat + Client Status Links
-- Run this in Supabase SQL Editor (after schema.sql and migration_002 have run).

-- ============================================================
-- 1. Multi-agent chat: tag each message with which agent handled it
-- ============================================================
alter table public.messages
  add column if not exists agent_type text not null default 'research'
  check (agent_type in ('research', 'drafting', 'compliance'));

create index if not exists messages_agent_type_idx on public.messages (case_id, agent_type, created_at);

-- ============================================================
-- 2. Client-facing read-only case status links
-- ============================================================
create table if not exists public.client_status_links (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique default encode(gen_random_bytes(18), 'hex'),
  view_count int not null default 0,
  created_at timestamptz default now()
);

alter table public.client_status_links enable row level security;

-- Only the case owner can create/manage their own share links
drop policy if exists "client_status_links_owner_all" on public.client_status_links;
create policy "client_status_links_owner_all" on public.client_status_links
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Public visitors reach this data only through get_case_status_by_token()
-- below (a security-definer function), never by reading this table
-- directly - so no public SELECT policy is added here.

create index if not exists client_status_links_token_idx on public.client_status_links (token);

-- Public status page reads through this function only, so it can bypass
-- cases' owner-only RLS in a controlled way - it deliberately returns only
-- a curated subset of fields (title, status, created_at, updated_at), never
-- ai_analysis, raw_description, or anything from messages/documents.
create or replace function public.get_case_status_by_token(p_token text)
returns table (
  case_title text,
  case_status text,
  filed_on timestamptz,
  last_updated timestamptz,
  link_valid boolean
)
language plpgsql
security definer set search_path = public
as $$
declare
  v_case_id uuid;
begin
  select cl.case_id into v_case_id
  from public.client_status_links cl
  where cl.token = p_token;

  if v_case_id is null then
    return query select null::text, null::text, null::timestamptz, null::timestamptz, false;
    return;
  end if;

  update public.client_status_links set view_count = view_count + 1 where token = p_token;

  return query
    select c.title, c.status, c.created_at, c.updated_at, true
    from public.cases c
    where c.id = v_case_id;
end;
$$;

grant execute on function public.get_case_status_by_token(text) to anon, authenticated;
