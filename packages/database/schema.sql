-- Nyaya-Agent :: Core App Schema
-- Run this once in Supabase SQL Editor (Project > SQL Editor > New query > Run)
-- Safe to re-run: uses IF NOT EXISTS / OR REPLACE throughout.

-- ============================================================
-- 1. PROFILES (extends Supabase auth.users)
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'client' check (role in ('client', 'lawyer')),
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- 2. CASES
-- ============================================================
create table if not exists public.cases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  raw_description text not null,
  status text not null default 'draft' check (status in ('draft', 'analyzed', 'lawyer_assigned', 'closed')),
  ai_analysis text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.cases enable row level security;

drop policy if exists "cases_owner_all" on public.cases;
create policy "cases_owner_all" on public.cases
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists cases_user_id_idx on public.cases (user_id);

-- ============================================================
-- 3. MESSAGES (multi-turn agent conversation per case)
-- ============================================================
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz default now()
);

alter table public.messages enable row level security;

drop policy if exists "messages_owner_all" on public.messages;
create policy "messages_owner_all" on public.messages
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists messages_case_id_idx on public.messages (case_id, created_at);

-- ============================================================
-- 4. LAWYERS (public directory)
-- ============================================================
create table if not exists public.lawyers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  name text not null,
  photo_url text,
  bar_council_reg_no text unique,
  specializations text[] default '{}',
  court_practices text[] default '{}',
  city text,
  experience_years int default 0,
  consultation_fee numeric,
  is_verified boolean default false,
  created_at timestamptz default now()
);

alter table public.lawyers enable row level security;

drop policy if exists "lawyers_public_read" on public.lawyers;
create policy "lawyers_public_read" on public.lawyers
  for select using (true);

drop policy if exists "lawyers_owner_write" on public.lawyers;
create policy "lawyers_owner_write" on public.lawyers
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- 5. CONSULTATIONS (booking requests)
-- ============================================================
create table if not exists public.consultations (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cases(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  lawyer_id uuid not null references public.lawyers(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'completed')),
  preferred_time timestamptz,
  created_at timestamptz default now()
);

alter table public.consultations enable row level security;

drop policy if exists "consultations_client_all" on public.consultations;
create policy "consultations_client_all" on public.consultations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "consultations_lawyer_read" on public.consultations;
create policy "consultations_lawyer_read" on public.consultations
  for select using (
    auth.uid() in (select user_id from public.lawyers where id = lawyer_id)
  );

drop policy if exists "consultations_lawyer_update" on public.consultations;
create policy "consultations_lawyer_update" on public.consultations
  for update using (
    auth.uid() in (select user_id from public.lawyers where id = lawyer_id)
  );

-- ============================================================
-- 6. Seed a couple of sample lawyers so the directory isn't empty
-- ============================================================
insert into public.lawyers (name, bar_council_reg_no, specializations, court_practices, city, experience_years, consultation_fee, is_verified)
values
  ('Adv. Arnab Sharma', 'DL/1234/2010', array['Criminal','Cyber'], array['Delhi High Court','Tis Hazari District Court'], 'New Delhi', 12, 3000, true),
  ('Adv. Priya Nair', 'MH/5678/2015', array['Family','Civil'], array['Bombay High Court'], 'Mumbai', 8, 2000, true),
  ('Adv. Rohit Verma', 'UP/7788/2018', array['Civil','Criminal'], array['Allahabad High Court','Lucknow District Court'], 'Lucknow', 6, 1800, true),
  ('Adv. Meera Iyer', 'TN/2233/2010', array['Corporate','Civil'], array['Madras High Court'], 'Chennai', 14, 4000, true)
on conflict (bar_council_reg_no) do nothing;
