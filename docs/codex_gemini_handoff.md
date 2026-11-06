# Codex / Gemini Handoff

> Status: Deprecated. This document is kept only as historical context.
> From `2026-04-27`, PaceKit no longer uses the Codex/Gemini split. Codex owns UI, business logic, data, tests, and final integration. Use `docs/codex_context_brief.md` for new-window handoff.

## Ownership

- Historical plan: Codex owned data schema, repositories, Riverpod providers, business rules, tests, and final integration.
- Historical plan: Gemini owned visual polish in `lib/src/features/**` widgets and shared visual components under `lib/src/shared/`.
- Current plan: Codex owns all implementation areas and should preserve the business rules documented in `docs/codex_context_brief.md`.

## UI Contract

The UI should consume these providers:

- `planTasksProvider(date)` for daily plan cards.
- `habitEntriesProvider(date)` for habit rows.
- `memoTasksProvider` for active DDL cards.
- `completionEventsProvider(DateRange)` for Day/Week/Month historical views.
- `profileProvider` and `themeModeProvider` for settings.

All task completion must call repository methods instead of mutating local UI state directly, because completion writes also create `CompletionEvent` rows.

## Visual Direction

- Keep the reference-image direction: light glass surfaces, soft green primary focus, purple/blue/orange functional accents, large pet presence, and rounded bottom navigation.
- Pet images are real assets from `pet/`. Do not use reference screenshots as page backgrounds.
- Preserve mobile-first ergonomics. If a detailed layout does not fit, stack content rather than shrinking text below readable sizes.

## Required Setup

After Flutter is installed:

```sh
flutter create --platforms=android .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

Drift will generate `lib/src/data/app_database.g.dart`.
