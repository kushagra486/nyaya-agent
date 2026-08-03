-- Nyaya-Agent :: Migration 009 - Lawyer Chat + expanded lawyer roster
-- Run this in Supabase SQL Editor (after prior migrations).

-- ============================================================
-- 1. Direct chat thread between a user and a specific lawyer.
--    Scoped by (lawyer_id, user_id) - a running conversation with that
--    lawyer, not tied to one specific case (the case in view when the
--    chat is opened is passed as context to the AI reply, best-effort,
--    but the thread itself persists across cases).
-- ============================================================
create table if not exists public.lawyer_messages (
  id uuid primary key default gen_random_uuid(),
  lawyer_id uuid not null references public.lawyers(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('user', 'lawyer')),
  content text not null,
  created_at timestamptz default now()
);

alter table public.lawyer_messages enable row level security;

drop policy if exists "lawyer_messages_owner_all" on public.lawyer_messages;
create policy "lawyer_messages_owner_all" on public.lawyer_messages
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists lawyer_messages_thread_idx on public.lawyer_messages (lawyer_id, user_id, created_at);

-- ============================================================
-- 2. Expanded lawyer roster - covers every major case type, not just
--    the original 4 seed lawyers (Criminal/Cyber, Family/Civil,
--    Civil/Criminal, Corporate/Civil). These are demo/placeholder
--    profiles, same as the original 4 - see the frontend's AI-simulated-
--    reply disclaimer for why that's disclosed to users.
-- ============================================================
insert into public.lawyers (name, bar_council_reg_no, specializations, court_practices, city, experience_years, consultation_fee, is_verified)
values
  ('Adv. Kavita Deshmukh', 'MH/9012/2012', array['Family','Matrimonial'], array['Bombay High Court','Pune Family Court'], 'Pune', 13, 2500, true),
  ('Adv. Sanjay Malhotra', 'DL/3345/2008', array['Corporate','Tax'], array['Delhi High Court','ITAT Delhi'], 'New Delhi', 17, 6000, true),
  ('Adv. Farah Sheikh', 'KA/6612/2016', array['Cyber','Intellectual Property'], array['Karnataka High Court'], 'Bengaluru', 9, 3500, true),
  ('Adv. Vikram Rathore', 'RJ/4478/2011', array['Property','Real Estate'], array['Rajasthan High Court','Jaipur District Court'], 'Jaipur', 14, 2800, true),
  ('Adv. Ananya Krishnan', 'TN/8821/2019', array['Consumer','Civil'], array['Madras High Court','Consumer Disputes Redressal Commission'], 'Chennai', 6, 1500, true),
  ('Adv. Harpreet Singh', 'PB/2290/2009', array['Labour','Employment'], array['Punjab and Haryana High Court'], 'Chandigarh', 16, 3200, true),
  ('Adv. Neha Kapoor', 'DL/7734/2014', array['Immigration','Corporate'], array['Delhi High Court'], 'New Delhi', 11, 4500, true),
  ('Adv. Ramesh Pillai', 'KL/5567/2007', array['Motor Accident Claims','Insurance'], array['Kerala High Court','MACT Ernakulam'], 'Kochi', 18, 2200, true),
  ('Adv. Divya Menon', 'KA/3398/2017', array['Medical Negligence','Consumer'], array['Karnataka High Court'], 'Bengaluru', 8, 3800, true),
  ('Adv. Arjun Bhatt', 'GJ/6650/2013', array['Banking','Corporate'], array['Gujarat High Court','DRT Ahmedabad'], 'Ahmedabad', 12, 4200, true),
  ('Adv. Simran Kaur', 'PB/1123/2020', array['Constitutional','Civil'], array['Punjab and Haryana High Court','Supreme Court of India'], 'Chandigarh', 5, 5000, true),
  ('Adv. Rahul Choudhary', 'WB/4456/2010', array['Environmental','Property'], array['Calcutta High Court'], 'Kolkata', 15, 2600, true),
  ('Adv. Priyanka Joshi', 'MH/8890/2015', array['Startup','Corporate'], array['Bombay High Court'], 'Mumbai', 10, 5500, true),
  ('Adv. Imran Ansari', 'UP/2276/2006', array['Criminal','Constitutional'], array['Allahabad High Court','Supreme Court of India'], 'Lucknow', 19, 4800, true),
  ('Adv. Lakshmi Narayan', 'TN/5543/2018', array['Family','Consumer'], array['Madras High Court'], 'Chennai', 7, 1900, true),
  ('Adv. Aditya Verma', 'DL/9987/2011', array['Cyber','Criminal'], array['Delhi High Court','Patiala House Courts'], 'New Delhi', 13, 3600, true)
on conflict (bar_council_reg_no) do nothing;
