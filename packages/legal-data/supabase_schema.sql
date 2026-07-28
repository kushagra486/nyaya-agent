-- Nyaya-Agent Legal Knowledge Base Schema
-- Run this in the Supabase SQL Editor (Free tier project) before ingesting.
-- Enables pgvector and creates the three RAG collections described in the spec.

create extension if not exists vector;

-- 1. Statutes & Acts Collection -----------------------------------------
create table if not exists statutes_index (
  id              bigserial primary key,
  act_name        text not null,             -- e.g. 'BNS 2023', 'IPC 1860'
  section_number  text not null,              -- e.g. '103', '318(4)'
  bns_mapped_section text,                    -- cross-reference to new code, null if act itself is new
  title           text not null,              -- offence / provision title
  content         text not null,              -- full section text or summary chunk
  enactment_year  int,
  metadata        jsonb default '{}'::jsonb,
  embedding       vector(384),                -- all-MiniLM-L6-v2 dimension (free, local)
  created_at      timestamptz default now()
);

create index if not exists statutes_index_embedding_idx
  on statutes_index using ivfflat (embedding vector_cosine_ops) with (lists = 100);

create index if not exists statutes_index_section_idx
  on statutes_index (act_name, section_number);

-- 2. Precedents Collection -----------------------------------------------
create table if not exists judgments_index (
  id                bigserial primary key,
  court_name        text not null,
  petitioner        text,
  respondent        text,
  ratio_decidendi   text,
  year              int,
  citation          text,
  content           text not null,
  embedding         vector(384),
  created_at        timestamptz default now()
);

create index if not exists judgments_index_embedding_idx
  on judgments_index using ivfflat (embedding vector_cosine_ops) with (lists = 100);

-- 3. Legal Directory Collection -------------------------------------------
create table if not exists lawyers_index (
  id                    bigserial primary key,
  user_id               uuid references auth.users(id),
  state_bar_council_no  text unique,
  city                  text,
  court_level           text,        -- District / HC / SC
  specialization_tags   text[],
  fee_range             numrange,
  is_verified           boolean default false,
  created_at            timestamptz default now()
);

-- Helper RPC for cosine-similarity search with the 0.75 hard-RAG threshold
create or replace function match_statutes(
  query_embedding vector(384),
  match_threshold float default 0.75,
  match_count int default 5
)
returns table (
  id bigint,
  act_name text,
  section_number text,
  title text,
  content text,
  similarity float
)
language sql stable
as $$
  select
    id, act_name, section_number, title, content,
    1 - (embedding <=> query_embedding) as similarity
  from statutes_index
  where 1 - (embedding <=> query_embedding) > match_threshold
  order by embedding <=> query_embedding
  limit match_count;
$$;
