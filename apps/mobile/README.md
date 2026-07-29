# Nyaya-Agent — Flutter App

Native mobile implementation of the Nyaya-Agent design spec (Material 3,
glassmorphic dark theme, gold/mint/navy palette, animated aurora background).

## ⚠️ Important: this hasn't been compiled or run yet

The sandbox this was written in has no Flutter SDK installed, and the domain
Flutter's SDK downloads from (`storage.googleapis.com`) is blocked by that
environment's network policy — so none of this code has been run through
`flutter analyze`, `pub get`, or an actual build. It's written carefully and
each file was manually re-checked for import/type consistency, but **you are
the first compiler this code will meet.** Budget time for a few round trips
fixing whatever `flutter analyze` flags — that's normal for any codebase this
size, hand-written or not, but especially so here.

## One-time setup

```bash
# 1. Install Flutter if you haven't: https://docs.flutter.dev/get-started/install

# 2. From inside this folder, generate the platform scaffolding
#    (android/, ios/, web/, etc. — not included here, since that's
#    machine-specific boilerplate `flutter create` generates for you):
flutter create --org com.kushagra486 --project-name nyaya_agent .

# 3. Install dependencies
flutter pub get

# 4. Run
flutter run
```

`flutter create .` will not overwrite the `lib/`, `pubspec.yaml`, or
`assets/` already here — it only fills in the missing platform folders.

## Backend — already live, no setup needed

This app points at the **same Supabase project and the same Vercel API
routes** as the web app (`apps/web` in the `nyaya-agent` GitHub repo):

- `lib/services/supabase_service.dart` — same URL/anon key, same tables
  (`profiles`, `cases`, `messages`, `lawyers`, `consultations`), same RLS
  policies. If you ran `packages/database/schema.sql` for the web app, this
  app works against that same data immediately.
- `lib/services/groq_service.dart` — calls the same `/api/analyze` and
  `/api/chat` Vercel functions, which hold `GROQ_API_KEY` server-side. This
  app never touches a Groq key directly, so there's nothing to protect
  against APK/IPA reverse-engineering.

If you ever move off the current `nyaya-agent-git-main-*.vercel.app` branch
alias (e.g. attach a custom domain), update `kApiBaseUrl` in
`groq_service.dart`.

## What's built

- Auth (email/password + magic link) — `screens/auth`
- Home/Dashboard — case list, new-case intake, Upload Document (marked
  coming soon, no OCR pipeline yet) — `screens/home`
- AI Legal Analysis — structured Facts/Statutes/Steps cards, gold monospace
  citations, floating chat button — `screens/analysis`
- Chat with Agent — multi-turn, suggestion chips, glass input bar —
  `screens/chat`
- Verify & Book Lawyer — specialization/court/experience filters, avatar
  cards, consultation requests — `screens/lawyers`
- History and Profile tabs, persistent bottom nav — `screens/app_shell.dart`
- Full design system: colors, typography, radius/shadow/glass tokens —
  `core/theme/`
- Reusable components: GlassCard, GoldButton, StatusChip, CaseCard,
  LawyerCard, SuggestionChip, AnalysisCard, FloatingChatButton, BottomNav,
  AnimatedBackground (aurora blobs) — `widgets/`

## What's not built yet

- Document upload/OCR (the "Upload Document" card is intentionally disabled)
- Lottie/Rive premium animations (spec mentions both; only `flutter_animate`
  fade/slide/scale transitions are wired in — add `lottie`/`rive` assets and
  packages if you want the richer motion)
- Push notifications (the bell icon is decorative)
- Haptic feedback on key actions (easy add: `HapticFeedback.mediumImpact()`
  in the relevant `onTap` handlers)
