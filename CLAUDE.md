# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app (`aspire_app`, package name used in test imports) for a mentorship platform. Currently a scaffold: one login screen with simulated auth. All six platform targets (android, ios, web, windows, linux, macos) are generated but unmodified.

## Toolchain

Flutter is pinned via FVM in [.fvmrc](.fvmrc) to **3.44.2**, and [.vscode/settings.json](.vscode/settings.json) points the Dart extension at `.fvm/versions/3.44.2`. `.fvm/` is gitignored, so a fresh clone needs `fvm install` before the IDE resolves the SDK.

Prefix commands with `fvm` to use the pinned version:

```bash
fvm install                 # after a fresh clone
fvm flutter pub get
fvm flutter run             # add -d chrome / -d windows to pick a device
fvm flutter analyze         # lint via analysis_options.yaml (flutter_lints ^4.0.0)
fvm flutter test
fvm flutter test test/widget_test.dart                          # single file
fvm flutter test --plain-name 'Counter increments smoke test'   # single test by name
```

## Architecture

Two orthogonal structures are layered on top of each other. Both are load-bearing — new code is expected to slot into the correct cell of the grid, and every existing file opens with a header comment stating which layer it belongs to. Keep that convention.

**Clean architecture** across [lib/](lib/), with the dependency rule pointing inward (`presentation` → `domain` ← `data`):

| Layer | Contents | Rule |
|---|---|---|
| [lib/domain/](lib/domain/) | `entities/`, `repositories/` (abstract contracts), `usecases/`, `failures/` (typed errors the contracts throw) | Pure Dart. No Flutter, no JSON, no external packages. |
| [lib/data/](lib/data/) | `models/` (JSON parsing), `repositories/` (implements domain contracts) | Talks to APIs/Firebase/DB. Models map to domain entities. |
| [lib/presentation/](lib/presentation/) | `widgets/`, `state/`, `utils/` | Depends on domain only, never on `data` directly. |
| [lib/core/](lib/core/) | `di/injection.dart`, `config/supabase_config.dart` | Cross-cutting wiring. |

**Atomic design** inside [lib/presentation/widgets/](lib/presentation/widgets/) — `atoms/` → `molecules/` → `organisms/` → `pages/`, each level composing only from levels below it. Atoms are context-free and take all behavior via callbacks; pages are the only level that touches state or DI. [login_page.dart](lib/presentation/widgets/pages/login_page.dart) → [login_form.dart](lib/presentation/widgets/organisms/login_form.dart) → [google_login_button.dart](lib/presentation/widgets/molecules/google_login_button.dart) → [custom_button.dart](lib/presentation/widgets/atoms/custom_button.dart) is the reference chain.

### State — signals, not setState

State lives in top-level `signal<T>` globals in [lib/presentation/state/](lib/presentation/state/) (`signals_flutter`). Widgets stay `StatelessWidget` and wrap the reactive region in `SignalBuilder(builder: (context) { ... })`, reading/writing `.value`. See [auth_state.dart](lib/presentation/state/auth_state.dart) and its use in `LoginPage`.

`Watch(...)` is the deprecated predecessor of `SignalBuilder` in signals_flutter 7.1 — do not add new uses. CI runs `analyze --fatal-infos`, so every `Watch` needs its own `// ignore: deprecated_member_use`; the migration was decided in issue #10 and completed in #9.

Signals are for **application** state. Ephemeral, purely-visual widget state (hover, for instance) does not belong in a global signal — a global would be shared by every card on screen. [hover_builder.dart](lib/presentation/widgets/atoms/hover_builder.dart) is the sanctioned exception and the only `StatefulWidget` in the onboarding.

Derived state is a `computed`, never a writable signal the UI sets by hand: `isAuthenticated` derives from the real session and `hasCompletedOnboarding` from the profile.

Actions that call use cases live in [auth_actions.dart](lib/presentation/state/auth_actions.dart), not in the pages: it is the only file in `presentation` that touches `getIt`, so logic shared by several screens (login, sign-up, logout) is not duplicated.

### DI — get_it

[lib/core/di/injection.dart](lib/core/di/injection.dart) exposes `getIt` and `setupDependencies()`, called from `main()` after `SupabaseConfig.initialize()` and before `runApp`. It registers `SupabaseClient`, both repositories (against their **domain contracts**, never the concrete class, so `presentation` never depends on `data`) and the use cases, all as lazy singletons. Wire new dependencies here rather than constructing them in widgets. `overrideDependency<T>()` swaps in a test double.

### Backend — Supabase

Project ref `dtvfucqamakudgbwuhbw`. [lib/core/config/supabase_config.dart](lib/core/config/supabase_config.dart) is the only place that holds credentials or calls `Supabase.initialize()`; URL and publishable key come from `--dart-define=SUPABASE_URL/SUPABASE_KEY` with the dev project as default. Data-layer code takes `SupabaseClient` from `getIt`, never `Supabase.instance.client`. The `public` schema is empty — every table added must have RLS enabled, since the publishable key ships in the client bundle.

### Styling

No hardcoded colors or spacing in widgets. Use [AppColors](lib/presentation/utils/app_colors.dart) and [AppConstants](lib/presentation/utils/constants.dart) (`defaultPadding`, `borderRadius`), multiplying `defaultPadding` for larger gaps. The theme seeds from `AppColors.primary` in [main.dart](lib/main.dart).

## Conventions

- Code comments, identifiers and user-facing UI strings are in **English**. Match this. (Issues and the documents under [docs/](docs/) stay in **Spanish** — that split is deliberate, see issue #35.)
- Every new file under `lib/` opens with a comment naming its layer, mirroring the existing files.
- Imports between layers are relative (`../../domain/...`), not `package:aspire_app/...`.

## Known scaffold gaps

Do not treat these as intentional; fix them when touching the relevant area.

- **`test/widget_test.dart` fails.** It is the untouched Flutter counter template asserting on `'0'`, `'1'`, and `Icons.add`, none of which exist in the login app. `fvm flutter test` is red until it is rewritten.
- **`fontFamily: 'Geist'` resolves to nothing.** It is set in the theme and repeated in individual `TextStyle`s, but no `fonts:` section exists in [pubspec.yaml](pubspec.yaml), so Flutter silently falls back to the system font.
- **Login is faked.** `LoginPage.onLoginWithGoogle` runs an inline `Future.delayed(2s)` and flips the signals directly; `onLogin` is an empty callback. The domain layer (issue #8) already defines the real `AuthRepository` contract and the `SignUp`/`SignIn`/`SignOut` use cases, but `AuthRepositoryImpl` is a stub that throws `UnimplementedError` and nothing is registered in `getIt` yet. Wiring it up is issue #9; the real flow must go through `getIt`.
