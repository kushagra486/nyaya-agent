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
