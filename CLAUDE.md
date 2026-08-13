# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and AI coding assistants when working with code in this repository.

## Project

Mentorship platform with AI for women in Bolivia entering tech (`aspire_app`).
The user flow: email/password auth with email confirmation, onboarding with learning track assignment (`frontend`, `backend`, `infrastructure`), topic tree with sequential micro-labs, profile page, and AI features (daily brief on dashboard, roadmap coach, lab hints, profile analysis).

## Toolchain

Flutter is pinned via FVM in [.fvmrc](.fvmrc) to **3.44.2**, and [.vscode/settings.json](.vscode/settings.json) points the Dart extension at `.fvm/versions/3.44.2`.

Always prefix commands with `fvm`:

```bash
fvm install                 # after a fresh clone
fvm flutter pub get
fvm flutter run             # add -d chrome / -d windows to pick a device
fvm flutter analyze --fatal-infos  # lint via analysis_options.yaml
fvm flutter test            # runs all 132+ unit and widget tests
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

- Code, comments, identifiers, and user-facing UI text are in **English**.
- Issues, PRs, and documentation in `docs/` are in **Spanish**.
- Imports between layers are relative (`../../domain/...`).
