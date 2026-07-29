# Changelog

All notable changes to Nyaya-Agent are documented here. Versions follow
[Semantic Versioning](https://semver.org/) in spirit (this is a pre-1.0
project, so minor bumps can include breaking changes).

The live site always reflects the latest version below. Older frontend
snapshots are archived and browsable at `apps/web/versions/`.

---

## v0.8.0 — Case Timeline
**Frontend:** `apps/web/versions/v0.8.0-nayay-bharat-v4.html` (= live `apps/web/index.html`)

First increment from the backend implementation spec (step 1 of its
suggested build order: "Cases + Timeline + Auth" — Cases/Auth already
existed, this adds Timeline). Built on the existing Supabase + Vercel
stack rather than standing up a separate Node/FastAPI + Redis service, per
the spec's own suggested stack section adapted to what's already live:

- New `timeline_events` table (`packages/database/migration_002_timeline.sql`)
  with RLS matching the existing owner-only pattern
- `/api/analyze` now extracts a chronological `timeline` array (date +
  description) from the case description alongside facts/statutes/steps,
  grounded in what's actually written — never invents dates
- New **Case Timeline** card in the Analysis view: AI-extracted events
  (gold dot) and user-added events (mint dot) rendered as a connected
  chronological list, with an inline "+ Add Event" form for manual entries
- Re-running analysis replaces prior AI-sourced timeline rows (avoids
  duplicates) without touching anything the user added manually

**Not yet built from the spec** (multi-agent chat split, Document Vault +
clause review, Citation Generator, multilingual, hearing reminders, Legal
Pulse ingestion) — these are substantial standalone efforts; several need
external accounts (Twilio/SendGrid/FCM for reminders) or a separate Python
runtime (OpenNyAI's actual NLP models can't run in Vercel's Node
functions — would substitute equivalent LLM-prompted extraction instead).
Next up per the spec's suggested order: single-agent chat is already live,
so the natural next step is the multi-agent split (Research/Drafting/
Compliance) on top of it.

## v0.7.0 — Scroll architecture rebuild
**Frontend:** `apps/web/versions/v0.7.0-nayay-bharat-v4.html` (= live `apps/web/index.html`)

v0.6.0's fixed-height `overflow:hidden` body + internal scroll container +
JS-driven hide-on-scroll header turned out fragile — it took two follow-up
patches (v0.6.1, v0.6.2) and was still confusing to actually use. Rebuilt
the whole scroll/layout model from scratch using plain, standard CSS
instead of JS scroll-listener tricks:

- **Body scrolls normally again** (removed `height:100vh; overflow:hidden`)
  — the page behaves like an ordinary website, no nested scroll containers
- **Sidebar is now `position:sticky`** with `max-height:100vh; overflow-y:auto`
  — the standard, battle-tested pattern for a persistent side nav; stays in
  view without any JS at all
- **Topbar stays `position:sticky`** (kept from before) but the fragile
  `hide-nav` JS class-toggling on scroll is gone entirely
- **Hero header now just scrolls away** with the page like a normal top
  banner, instead of trying to animate its own height/padding away — far
  more predictable
- **Fixed a real, separate bug found in the process:** on mobile
  (≤980px) the sidebar was `position:fixed` off-screen with **no way to
  open it** — there was no hamburger button wired up at all, so navigation
  was completely inaccessible on phones. Added a working menu button in
  the hero, a tap-to-close backdrop, and auto-close on any nav selection.

## v0.6.2 — Hero header collapses on scroll
**Frontend:** `apps/web/versions/v0.6.2-nayay-bharat-v4.html` (= live `apps/web/index.html`)

- The hero masthead now collapses (height, padding, and border animate away
  — not just a floating slide-over) when scrolling down inside a view,
  reusing the same auto-hide logic already driving the per-view topbar.
  Reclaims real vertical space on short mobile viewports instead of a fixed
  header permanently eating into the visible content area. Scrolls back
  into view immediately when scrolling up.

## v0.6.1 — Scroll fix
**Frontend:** `apps/web/versions/v0.6.1-nayay-bharat-v4.html` (= live `apps/web/index.html`)

- Fixed: page couldn't scroll at all on mobile. v0.6.0's layout change made
  `body` a fixed-height `overflow:hidden` flex container so the sidebar and
  main panel could scroll independently, but `.main` itself was never given
  `overflow-y:auto` — so there was no scrollable container anywhere on
  narrow viewports where content overflows immediately. Added
  `overflow-y:auto; height:100%` (plus `-webkit-overflow-scrolling:touch`
  for iOS momentum scrolling) to `.main`, matching the pattern already used
  on `.sidebar`.

## v0.6.0 — "Nayay Bharat v4"
**Frontend:** `apps/web/versions/v0.6.0-nayay-bharat-v4.html` (= live `apps/web/index.html`)

- New hero masthead header with animated gradient sweep and a cycling tagline
  (Research / Draft / Explain / Analyze / Verify)
- Command palette (**Ctrl/Cmd+K**) — search and jump to any view, start a new
  case, or continue a chat, all wired to real navigation
- Chat now shows a real "AI thinking" sequence (searching context → reading
  laws → finding precedents → answer ready) that holds until the actual
  `/api/chat` response arrives, rather than a fixed fake delay
- Message action toolbar on chat replies: copy (real clipboard copy),
  regenerate (re-sends the real prior message), like/dislike, share
- Sidebar restructured: New Chat button, "AI Tools" section (Draft Petition
  and Legal Notice Generator marked coming-soon via toast; Acts & Statutes
  wired to the real statute Library), expanded Records (Documents/Settings
  coming-soon; Case History and Profile fully real), and a live "Recent"
  list showing your 2 most recent cases
- Toast notification system for coming-soon actions

## v0.5.0 — "Nayay Bharat v3" wired
**Frontend:** `apps/web/versions/v0.5.0-nayay-bharat-v3.html`

- Uploaded static design fully wired to the real backend: Supabase
  auth/cases/messages/lawyers/consultations, existing Vercel `/api/analyze`
  and `/api/chat` proxies
- Added the three views that were dead nav links in the original mockup:
  Case History, Legal Library (searchable table of all 107 statute
  mappings, embedded inline), Profile (email + sign out)
- Replaced the React SPA (`apps/web/src/*`) as the deployed frontend — Vite
  now passes this single static `index.html` through unchanged
- Added anonymous sign-in as a dev/testing bypass (still a real, RLS-safe
  Supabase session, not a fake UI skip)

## v0.4.0 — Design system alignment
- Restyled the case-dashboard React app to the Stitch mockup's dark
  charcoal / mint / amber palette, Inter typography, bottom nav
  (Dashboard/Lawyers/History/Profile), structured Facts/Statutes/Steps
  analysis cards, lawyer avatar-initials + court/experience filters

## v0.3.0 — Dashboard + Supabase backend
- Full Supabase schema (`packages/database/schema.sql`): profiles, cases,
  messages, lawyers, consultations, with row-level security throughout
- React screens: Auth (password + magic link), Dashboard, AI Analysis, Chat,
  Lawyer Booking, all backed by real data
- `apps/mobile`: Flutter app implementing the same product, sharing the
  same Supabase project and the same Vercel API routes

## v0.2.0 — Server-side Groq proxy
- Moved Groq calls from client-side (BYOK) to `apps/web/api/analyze.js` and
  `api/chat.js` — Vercel serverless functions holding `GROQ_API_KEY` as a
  server-only environment variable, with per-IP rate limiting
- Deployed to Vercel (git-linked, auto-deploy on push) alongside the
  existing GitHub Pages static mirror

## v0.1.0 — Initial release
- `packages/legal-data`: ingestion pipeline converting IPC/CrPC/Evidence Act
  ↔ BNS/BNSS/BSA bare-act CSVs into Supabase pgvector embeddings
- First web app: Section Correlator, AI-assisted Statute Matching, Full
  Register browse table
- GitHub repo + GitHub Actions → GitHub Pages deploy workflow established
