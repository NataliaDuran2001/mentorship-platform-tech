# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and AI coding assistants when working with code in this repository.

## Project

Mentorship platform with AI for women in Bolivia entering tech (`aspire_app`).
The user flow: email/password auth with email confirmation, onboarding with learning track assignment (`frontend`, `backend`, `infrastructure`, `uiux`, `project_management`), topic tree with sequential micro-labs, profile page, and AI features (daily brief on dashboard, roadmap coach, lab hints, profile analysis).

### Learning path shape

The path is levelled through the existing hierarchy: a level (`Basic`, `Intermediate`, `Advanced`) is a parent topic and its sections are its children. There is no difficulty column — do not add one without a reason the hierarchy cannot cover.

A topic is a sequence of `lab_challenges`, and `theory` is one of the four `challenge_type` values. It is an explanation the learner acknowledges with "Got it": it takes its place in the sequence, counts toward the lab's progress bar, and gets no AI hint. That is what lets a topic alternate explaining and practising without a second flow. Theory density is meant to fall as the level rises.

**A section never explains twice in a row.** Each concept is followed by the practice that exercises *that* concept — not by another explanation, and not by an exercise for a different one. Migration `20260815000002` fixed the eight sections that broke this and ships a query that walks all 75; re-run it after touching content, and it names any section that regressed.

**Scoring.** A finished lab shows `completedSteps of totalSteps`, and every step counts — explanations included, because walking past them is progress and a denominator that ignores them reads as a bug to anyone who counted their screens. What differs is how a step is earned: an explanation the moment it is acknowledged, an exercise only when answered right on the **first** check. Retrying is how the lab advances, so a plain "solved" count would be N of N for everyone. Because explanations are always earned, `perfect` still means every exercise right first time — theory can never hand one out. Only the exercise numbers persist ([user_progress.score_exercises_*](supabase/migrations/20260815000001_user_progress_score.sql)); the step total is derived from the topic tree, which already knows how many explanations a section has. The better of two runs wins, so reviewing a section can never cost a learner the record of having known it.

All five tracks are on this shape (seeds `20260814000002` and `20260814000004..7`, plus `20260815000002`; ~46 challenges per track, 235 in total). The guided quiz still recommends only among the three technical tracks; `uiux` and `project_management` are reachable through direct selection in step 2 and the quiz's override chips. Adding a track means: enum value in [roadmap_track.dart](lib/domain/entities/roadmap_track.dart) (at the end — the tie-break depends on order), entry in `trackLabels`, row in `public.tracks`, and its seed. [track_labels_test.dart](test/presentation/track_labels_test.dart) fails if the map and the enum drift apart.

## Toolchain

Flutter is pinned via FVM in [.fvmrc](.fvmrc) to **3.44.2**, and [.vscode/settings.json](.vscode/settings.json) points the Dart extension at `.fvm/versions/3.44.2`.

Always prefix commands with `fvm`:

```bash
fvm install                 # after a fresh clone
fvm flutter pub get
fvm flutter run             # add -d chrome / -d windows to pick a device
fvm flutter analyze --fatal-infos  # lint via analysis_options.yaml
fvm flutter test            # runs all 187+ unit and widget tests
fvm flutter test test/presentation/roadmap_test.dart   # single test file
```

## Architecture

Clean architecture across [lib/](lib/) with atomic design for UI widgets:

### Clean Architecture Layers
Dependency rule points inward (`presentation` → `domain` ← `data`):

| Layer | Path | Description & Rules |
|---|---|---|
| Domain | [lib/domain/](lib/domain/) | `entities/`, `repositories/` (abstract contracts), `usecases/`, `failures/`. Pure Dart. No Flutter, no JSON, no external packages. |
| Data | [lib/data/](lib/data/) | `models/` (JSON mapping), `repositories/` (implements domain contracts). Communicates with Supabase API & Edge Functions. |
| Presentation | [lib/presentation/](lib/presentation/) | `widgets/`, `state/`, `utils/`. UI, signals state, actions. Depends on domain only. |
| Core | [lib/core/](lib/core/) | `di/injection.dart`, `config/supabase_config.dart`, router config. |

Every file opens with a header comment declaring its layer (e.g. `// Layer: Domain`). Maintain this convention.

### Navigation & Routing
- Uses `go_router` with shell navigation for responsive layouts (desktop drawer / mobile bottom nav).
- Route guards check auth session and onboarding completion (`isAuthenticated`, `hasCompletedOnboarding`). Pages do not navigate directly; guards redirect based on signal state.

### State Management — Signals
- State lives in top-level `signal<T>` globals in [lib/presentation/state/](lib/presentation/state/).
- Widgets stay `StatelessWidget` and wrap reactive regions in `SignalBuilder(builder: (context) { ... })`. Do NOT use deprecated `Watch`.
- Derived state uses `computed`, never writable signals set manually by UI.
- Actions calling use cases live in `*_actions.dart` files (the only presentation files touching `getIt`).

### Backend & AI Features — Supabase + Moonshot Kimi3
- **Supabase Project**: `dtvfucqamakudgbwuhbw`. Database has RLS enabled on all exposed tables (`public`).
- **AI Integration**: Calls to AI pass through Supabase Edge Functions (`analyze-profile`, `daily-brief`, `lab-hint`, `roadmap-coach`) using Moonshot AI (`kimi-k3`).
  - `KIMI_API_KEY` lives securely in Edge Functions environment.
  - `kimi-k3` uses default temperature (`1.0`); do NOT pass custom `temperature` parameter in fetch calls.
  - AI responses are cached in `ai_profile_insights` (24h cache for daily brief).
  - Elegant degradation: AI failures fall back gracefully to deterministic logic or static messages.

### Styling — Luminous Clarity Design System
- Use [AppColors](lib/presentation/utils/app_colors.dart) and [AppConstants](lib/presentation/utils/constants.dart).
- Never hardcode colors or arbitrary spacing numbers.

## Conventions

- Code, comments and identifiers are in **English**.
- User-facing UI text goes through `tr('English', 'Español')` from [translate.dart](lib/presentation/utils/translate.dart) — both languages at the call site, no catalog and no keys. `tr` reads the `appLanguage` signal, so it only repaints inside a `SignalBuilder`; a string resolved outside one will freeze at whatever language was current when it was built.
- Issues, PRs, and documentation in `docs/` are in **Spanish**.
- Imports between layers are relative (`../../domain/...`).
