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
