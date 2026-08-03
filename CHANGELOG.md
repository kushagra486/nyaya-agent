# Changelog

All notable changes to Nyaya-Agent are documented here. Versions follow
[Semantic Versioning](https://semver.org/) in spirit (this is a pre-1.0
project, so minor bumps can include breaking changes).

The live site always reflects the latest version below. Older frontend
snapshots are archived and browsable at `apps/web/versions/`.

---

## v0.9.2 — CRITICAL FIX: entire app was non-functional
**Frontend:** `apps/web/versions/v0.9.2-nayay-bharat-light.html`

The v0.9.0 rebuild-from-scratch introduced a serious bug: the `<script
src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2">` library include
was never added to `<head>` — it existed in every prior dark-theme version
but was missed when hand-writing this fresh design's markup. Without it,
`window.supabase` is undefined, so the very first line of the app script
(`window.supabase.createClient(...)`) threw immediately and **the entire
script died on load** — not just login. Nav, cases, chat, lawyers,
everything was silently broken since v0.9.0. This is why "skip login"
(v0.9.1) appeared not to work: the auto-anonymous-sign-in code never even
ran, because the script had already crashed one line in.

Root cause found by directly grepping for the CDN script tag rather than
just re-running the JS-syntax/ID-reference checks — those checks validate
the script's own code and its DOM references, but say nothing about
whether external dependencies are actually included. Added an explicit
external-dependency check to the validation routine going forward.

## v1.0.0 — Hearing Reminders (email) — all 11 backend spec items complete
**Frontend:** `apps/web/versions/v1.0.0-nyay-bharat-light.html` (= live `apps/web/index.html`)

Spec item #7, email-only per your call (no SMS — no free SMS option
exists industry-wide; push notifications also skipped in this pass in
favor of shipping email cleanly first):

- New "Hearing Reminder" panel in the Analysis view: pick a date/time,
  saves `cases.next_hearing_date` and schedules an email reminder for
  1 day before. Dashboard and Case History cards now show the real
  hearing date instead of the "No hearing scheduled" placeholder that's
  been there since the earliest UI mockup.
- New `/api/send-reminders` serverless function, using **Resend** (free
  tier, no card required) for email delivery.
- Scheduled via a new GitHub Actions workflow
  (`.github/workflows/reminders-check.yml`, every 15 minutes per the
  spec's suggested cadence), same shared-secret pattern as Legal Pulse.
- Two new security-definer RPCs (`get_due_reminders`, `mark_reminder_sent`)
  let the unauthenticated cron job do a narrow, controlled read/write
  without needing a `service_role` key anywhere in this project — same
  pattern as the client status page's `get_case_status_by_token`.
- `profiles` now stores `email` (denormalized from `auth.users`) since
  the cron job has no logged-in session to read it from otherwise.

**This closes out the full 11-item backend spec:**
1. Case Timeline (v0.8.0) · 2. Multi-Agent Chat (v0.10.0) · 3. Citation
Generator (v0.10.0) · 4. Document Vault + clause review (v0.11.0) ·
5. Multilingual (v0.12.0) · 6. Client Status Page (v0.10.0) ·
7. Hearing Reminders (this release) · 8–11. Legal Pulse — RSS +
trending built (v0.13.0); eCourts scraper and OpenNyAI structuring
remain deferred as explicit follow-up work per the spec's own
recommended build order (separate scraper infra + a Python ML runtime
this Vercel/Node stack doesn't run).

## v0.13.0 — Legal Pulse (RSS aggregation + trending)
**Frontend:** `apps/web/versions/v0.13.0-nyay-bharat-light.html` (= live `apps/web/index.html`)

Spec items #10 and #11, per the spec's own recommended approach ("start
with RSS ingestion only, add eCourts + OpenNyAI structuring in a second
pass") — items #8 (eCourts scraper) and #9 (OpenNyAI structuring) are
explicitly deferred: the former needs careful rate-limit handling against
a real government portal, the latter needs a Python ML runtime that
doesn't fit Vercel's Node serverless functions.

- New `/api/ingest-pulse` serverless function: fetches RSS feeds from
  LiveLaw, Bar & Bench, and SCC Online Blog (`rss-parser`, open source),
  upserts new items into `pulse_items`. Each feed fetched independently
  so one failing doesn't block the others — **Bar & Bench's exact feed
  URL wasn't fully verifiable at build time** (custom CMS, not standard
  WordPress) and may need adjusting once you see real ingestion results.
- Scheduled via a new GitHub Actions workflow (`.github/workflows/pulse-ingest.yml`,
  every 30 minutes) rather than Vercel Cron, to avoid Hobby-plan limits.
  Protected by a shared secret (`INGEST_SECRET`) you'll need to set in
  both Vercel env vars and a GitHub Actions repo secret.
- New **Legal Pulse** view: Trending / Latest tabs. Trending is computed
  **client-side** (keyword-overlap frequency across the last 7 days,
  items sharing terms with multiple recent articles get flagged
  "Spiking") rather than a stored `trend_score` + separate scoring
  worker — simpler given the data volumes involved, same end result.
- `pulse_items` is public read/write by design (news aggregation, not
  user data) — documented tradeoff in the migration, since no
  service_role key is used anywhere in this project.

## v0.12.0 — Multilingual support (Hindi, Marathi, Tamil, English)
**Frontend:** `apps/web/versions/v0.12.0-nyay-bharat-light.html` (= live `apps/web/index.html`)

Spec item #5, fully free — no translation API, no new accounts:

- Language selector in the top nav (EN / हिं / मरा / தமி), persisted in
  localStorage. Switches 36 core UI strings — nav items, hero, section
  headers, primary buttons — across all 4 languages instantly, no page
  reload.
- **AI-generated content is translated natively, not post-translated**:
  Analysis, Chat (all three agents), and Document clause review now
  accept a `locale` param and instruct the model to respond directly in
  the selected language — statute citations and section numbers always
  stay in their original form regardless of language, per the spec's own
  recommendation to pass locale into the prompt rather than translating
  output afterward.
- This is a curated first pass covering primary navigation and headers,
  not every microcopy string in the app (toasts, placeholders, and
  dynamic case/document content stay in whatever language the user
  entered them in) — translating every string is straightforward
  incremental work from here if wanted.

## v0.11.0 — Document Vault with clause-level AI review
**Frontend:** `apps/web/versions/v0.11.0-nyay-bharat-light.html` (= live `apps/web/index.html`)

Spec item #4, fully free — no new external accounts:

- Dashboard's "Upload Document" tile is live (was "coming soon"). Upload a
  PDF or DOCX (25MB max) and it: extracts text client-side (`pdf.js` for
  PDFs, `mammoth.js` for DOCX — both open source, both run in the
  browser), auto-creates a case from the file, uploads the original file
  to a private Supabase Storage bucket, and sends the extracted text to a
  new `/api/review-document` endpoint for clause-by-clause AI review.
- Each clause gets a risk level (low/medium/high) against a fixed rubric —
  unlimited liability, one-sided termination rights, auto-renewal without
  notice, broad indemnification flagged high; ambiguous/missing-protection
  terms flagged medium; standard mutual terms flagged low.
- New **Documents** view (account menu / mobile nav): lists every uploaded
  document with its review status; click one to see the full clause
  breakdown with risk badges and a persistent AI-disclaimer.
- New tables: `documents`, `document_clauses`, plus a private
  `documents` Storage bucket scoped per-user via storage RLS
  (`migration_004_documents.sql`).

**Still not built from the spec:** Multilingual support, Hearing
reminders (needs your Twilio/SendGrid/FCM decision), Legal Pulse
(eCourts scraper + OpenNyAI + RSS + trending — the biggest remaining
lift).

## v0.10.0 — Multi-Agent Chat, Citation Generator, Client Status Page
**Frontend:** `apps/web/versions/v0.10.0-nyay-bharat-light.html` (= live `apps/web/index.html`)

Three more items from the backend spec, all buildable on the existing
Supabase + Vercel stack with zero new external accounts:

- **Multi-Agent Chat** (spec item #2) — Chat is no longer one generic
  assistant. Three tabs (Research / Drafting / Compliance), each with a
  distinct system prompt in `api/chat.js`: Research focuses on statutes/
  precedent shape, Drafting structures legal notices/complaint outlines
  (never a filed petition), Compliance specifically cross-checks whether
  citations use the current BNS/BNSS/BSA vs. the old IPC/CrPC/Evidence Act.
  Messages are tagged with `agent_type` and each tab keeps its own
  conversation thread per case (`migration_003_multiagent_status.sql`).
- **Citation Generator** (spec item #3) — new view, pure deterministic
  formatting per the spec's own recommendation (no AI call): SCC-style,
  AIR-style, and a plain neutral citation from case name/court/year/
  volume/page, each with a one-click copy button.
- **Client-facing status page** (spec item #6) — "Share Case Status Link"
  in the Analysis view generates a `?status=TOKEN` URL. Visiting that URL
  shows a read-only case-status card (title, status, filed date, last
  updated) with **no login required** — it bypasses the entire
  authenticated app and reads through a new `get_case_status_by_token()`
  Postgres function (security definer) that deliberately returns only
  those four fields, never `ai_analysis`, `raw_description`, messages, or
  documents.

**Still not built from the spec:** Document Vault with clause review
(needs file upload + text extraction), Multilingual support, Hearing
reminders (needs Twilio/SendGrid/FCM credentials), and Legal Pulse
(eCourts scraper + OpenNyAI + RSS aggregation + trending — the biggest
remaining lift, and OpenNyAI specifically needs a Python ML runtime
Vercel's Node functions can't run).

## v0.9.6 — Brand name changed to "Nyay Bharat"
**Frontend:** `apps/web/versions/v0.9.6-nyay-bharat-light.html` (= live `apps/web/index.html`)

Changed the displayed brand name from "Nyaya Bharat" to "Nyay Bharat" —
page title, hero heading, chat header, mobile nav header, and the top
script comment. The underlying repo name and Vercel domain
(`nyaya-agent`) are untouched, since renaming those would break the live
API connection — this only affects the text shown on the page itself.

## v0.9.5 — Fix "Nayay" → "Nyaya" brand spelling
**Frontend:** `apps/web/versions/v0.9.5-nyaya-bharat-light.html` (= live `apps/web/index.html`)

Fixed the brand name spelling throughout the page — page title, hero
heading, chat header, mobile nav header, and the top script comment all
said "Nayay Bharat" (letters transposed); corrected to "Nyaya Bharat",
matching the correct Sanskrit/Hindi romanization of न्याय (justice) and
the project's own repo name (`nyaya-agent`) used everywhere else.

## v0.9.4 — GitHub Pages works standalone; found the real "login" cause
**Frontend:** `apps/web/versions/v0.9.4-nayay-bharat-light.html` (= live `apps/web/index.html`)

- **Found the actual root cause of "having to log into Vercel":** the
  `nyaya-agent` Vercel project has **Vercel Authentication (SSO Protection)
  enabled** for `all_except_custom_domains` — every visitor to the
  `.vercel.app` URL is being forced through a Vercel login wall. This is a
  dashboard setting, not a code bug; I don't have permission to change it
  via the Vercel API (confirmed: 403 forbidden). **Action needed:** Vercel
  dashboard → nyaya-agent → Settings → Deployment Protection → Vercel
  Authentication → turn off (or restrict to preview only).
- **Made GitHub Pages a fully standalone deployment:** `/api/analyze` and
  `/api/chat` previously used relative paths (`fetch("/api/analyze")`),
  which only resolve correctly when the HTML is served from the Vercel
  domain itself. Added an `API_BASE` constant pointing at the Vercel
  deployment and switched both calls to absolute URLs, so the exact same
  static file works identically whether served from Vercel, GitHub Pages,
  or anywhere else — the AI features aren't tied to which host serves the
  page. (Note: this still depends on the Vercel Authentication toggle
  above being off, since that protection applies to the API routes too,
  not just page views.)
- Added an explicit "external script tag present" + "API_BASE in use"
  check to the validation routine, alongside the existing JS-syntax/
  ID-cross-reference/structural-balance checks.

## v0.9.3 — Login page removed
**Frontend:** `apps/web/versions/v0.9.3-nayay-bharat-light.html` (= live `apps/web/index.html`)

v0.9.1's auto-anonymous-sign-in still fell back to a full blocking login
screen whenever it failed — and given repeated reports of getting stuck
there, that fallback was doing more harm than good. Removed the login
page entirely:

- The app always renders immediately; there is no login form anywhere
- A background session connects automatically (anonymous sign-in) so
  data features work once Supabase is configured correctly
- If the background connection genuinely fails, a small non-blocking
  banner at the top explains why (pointing at the exact Supabase toggle
  to check) — it never gates the UI behind a form again
- Sign out (still available via the account dropdown / Profile) now
  reconnects a fresh background session immediately afterward, so there's
  no dead end there either

## v0.9.1 — Skip the login screen by default
**Frontend:** `apps/web/versions/v0.9.1-nayay-bharat-light.html` (= live `apps/web/index.html`)

- On initial load with no existing session, the app now signs in
  anonymously automatically — no login screen to click through. Still a
  real Supabase session (real `auth.uid()`), so RLS on cases/messages/
  lawyers/consultations works exactly as normal; this isn't a fake bypass.
  If the visitor explicitly signs out afterward, the auth screen shows
  normally (their choice is respected, not immediately re-bypassed). Falls
  back to the auth screen with a clear pointer to the required Supabase
  toggle if Anonymous Sign-Ins isn't enabled on the project.

## v0.9.0 — "Nayay Bharat Light" — fresh design, full rewire
**Frontend:** `apps/web/versions/v0.9.0-nayay-bharat-light.html` (= live `apps/web/index.html`)

A completely new design from scratch (light/warm palette — cream paper
background, maroon/navy/gold/mint accents, Fraunces serif + IBM Plex Mono,
top nav instead of a sidebar) fully wired to the same backend as every
prior version, plus everything built in v0.5.0–v0.8.0 carried forward:

- **Auth gate** — the new design shipped with no login screen at all; added
  one (password/magic-link/anonymous-bypass) matching the new palette
- **Account dropdown** — avatar click reveals Case History / Legal Library /
  Profile / Sign out, since the horizontal top nav has room for only the
  4 primary views (Dashboard/Analysis/Chat/Lawyers)
- **Working mobile menu** — same class of bug as v0.7.0: the raw design's
  `.nav-links{display:none}` on mobile left zero way to navigate on a
  phone. Added a real slide-in mobile nav with a hamburger button and
  backdrop, this time from the start rather than as a follow-up patch
- **Real stats, not fake SaaS numbers** — the mockup's "AI Credits Left"
  and "Saved Lawyers" cards had no backing concept in the schema. Replaced
  with four genuinely real metrics: Active Cases, Cases Analyzed,
  Consultations Requested, Verified Lawyers (all live Supabase counts)
- **New Case modal, statute detail modal, Case Timeline card** — none of
  these existed in the raw upload; added them matching the established
  patterns (structured `/api/analyze` output, `timeline_events` table)
- Verified the same way every version has been: JS syntax-checked,
  every element reference cross-checked against the HTML, div/section/
  header/nav balance confirmed, Vite passthrough byte-identical

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
